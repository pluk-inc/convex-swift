// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let releaseTag = "0.8.8"
let releaseChecksum = "1cd863994f294859bf69445b1a65ff05d1f4f005decda25968f00f9a34b75274"

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
