// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PACKAGE",
    platforms: [.iOS(.v13), .macOS(.v12), .watchOS(.v6), .tvOS(.v13)],
    products: [
        .library(name: "PACKAGE", targets: ["PACKAGE"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "PACKAGE", dependencies: [], path: "Sources"),
        .testTarget(name: "PACKAGETests", dependencies: ["PACKAGE"], path: "Tests"),
    ]
)
