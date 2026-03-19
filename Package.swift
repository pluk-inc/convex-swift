// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let releaseTag = "0.8.7"
let releaseChecksum = "5630c89fa6a57161d3ed53d56a66d2e04ead70debadb1953b208ad0b44cbcdb4"

let binaryTarget: Target = .binaryTarget(
  name: "ConvexMobileCoreRS",
  url: "https://github.com/pluk-inc/convex-swift/releases/download/\(releaseTag)/libconvexmobile-rs.xcframework.zip",
  checksum: releaseChecksum
)

let package = Package(
  name: "ConvexMobile",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "ConvexMobile",
      targets: ["ConvexMobile"])
  ],
  targets: [
    binaryTarget,
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "ConvexMobile",
      dependencies: [.target(name: "UniFFI")]),
    .target(
      name: "UniFFI",
      dependencies: [.target(name: "ConvexMobileCoreRS")],
      path: "Sources/UniFFI"),
    .testTarget(
      name: "ConvexMobileTests",
      dependencies: ["ConvexMobile"]),
  ]
)
