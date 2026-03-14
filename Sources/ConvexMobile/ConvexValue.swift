import Foundation

/// A dynamic, type-safe representation of any Convex value.
///
/// Use ``ConvexValue`` when the response schema is unknown at compile time:
/// ```swift
/// let result: ConvexValue = try await client.query(name: "myQuery", with: args)
/// result["fieldName"]?.stringValue
/// ```
///
/// For known schemas, define a `Decodable` struct and use that instead:
/// ```swift
/// let user: User = try await client.query(name: "getUser", with: args)
/// ```
public enum ConvexValue: Decodable, Equatable, CustomStringConvertible {
  case null
  case bool(Bool)
  case number(Double)
  case string(String)
  case bytes(Data)
  case array([ConvexValue])
  case object([String: ConvexValue])

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if container.decodeNil() {
      self = .null
      return
    }

    // Bool must be checked before number since Bool is bridgeable to number
    if let bool = try? container.decode(Bool.self) {
      self = .bool(bool)
      return
    }

    if let number = try? container.decode(Double.self) {
      self = .number(number)
      return
    }

    if let string = try? container.decode(String.self) {
      self = .string(string)
      return
    }

    if let object = try? container.decode([String: ConvexValue].self) {
      // Handle Convex special encodings
      if let intStr = object["$integer"]?.stringValue,
        let data = Data(base64Encoded: intStr)
      {
        let int64 = data.withUnsafeBytes { $0.load(as: Int64.self) }
        self = .number(Double(int64))
        return
      }
      if let floatStr = object["$float"]?.stringValue,
        let data = Data(base64Encoded: floatStr)
      {
        let float64 = data.withUnsafeBytes { $0.load(as: Double.self) }
        self = .number(float64)
        return
      }
      if let base64 = object["$bytes"]?.stringValue,
        let data = Data(base64Encoded: base64)
      {
        self = .bytes(data)
        return
      }
      self = .object(object)
      return
    }

    if let array = try? container.decode([ConvexValue].self) {
      self = .array(array)
      return
    }

    throw DecodingError.typeMismatch(
      ConvexValue.self,
      DecodingError.Context(
        codingPath: decoder.codingPath,
        debugDescription: "Cannot decode ConvexValue"))
  }

  // MARK: - Subscripts

  /// Access a value by key in an object.
  public subscript(key: String) -> ConvexValue? {
    guard case .object(let dict) = self else { return nil }
    return dict[key]
  }

  /// Access a value by index in an array.
  public subscript(index: Int) -> ConvexValue? {
    guard case .array(let arr) = self, index >= 0, index < arr.count else { return nil }
    return arr[index]
  }

  // MARK: - Value accessors

  public var boolValue: Bool? {
    guard case .bool(let v) = self else { return nil }
    return v
  }

  public var numberValue: Double? {
    guard case .number(let v) = self else { return nil }
    return v
  }

  public var intValue: Int64? {
    guard case .number(let v) = self else { return nil }
    return Int64(exactly: v)
  }

  public var stringValue: String? {
    guard case .string(let v) = self else { return nil }
    return v
  }

  public var bytesValue: Data? {
    guard case .bytes(let v) = self else { return nil }
    return v
  }

  public var arrayValue: [ConvexValue]? {
    guard case .array(let v) = self else { return nil }
    return v
  }

  public var objectValue: [String: ConvexValue]? {
    guard case .object(let v) = self else { return nil }
    return v
  }

  public var isNull: Bool {
    if case .null = self { return true }
    return false
  }

  // MARK: - Conversion to Foundation types

  /// Converts to a Foundation type (`[String: Any]`, `[Any]`, `String`, `Double`, `Bool`, `Data`, or `NSNull`).
  public var anyValue: Any {
    switch self {
    case .null: return NSNull()
    case .bool(let v): return v
    case .number(let v): return v
    case .string(let v): return v
    case .bytes(let v): return v
    case .array(let arr): return arr.map { $0.anyValue }
    case .object(let dict): return dict.mapValues { $0.anyValue }
    }
  }

  // MARK: - CustomStringConvertible

  public var description: String {
    switch self {
    case .null: return "null"
    case .bool(let v): return "\(v)"
    case .number(let v):
      if v == v.rounded(.towardZero) && v < 1e15 && v > -1e15 {
        return "\(Int64(v))"
      }
      return "\(v)"
    case .string(let v): return "\"\(v)\""
    case .bytes(let v): return "<\(v.count) bytes>"
    case .array(let arr): return "[\(arr.map(\.description).joined(separator: ", "))]"
    case .object(let dict):
      let pairs = dict.sorted(by: { $0.key < $1.key }).map { "\"\($0.key)\": \($0.value)" }
      return "{\(pairs.joined(separator: ", "))}"
    }
  }
}
