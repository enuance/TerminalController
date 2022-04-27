// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TerminalController",
    products: [
        .library(name: "TerminalController", targets: ["TerminalController"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "TerminalController", dependencies: []),
        .testTarget(name: "TerminalControllerTests", dependencies: ["TerminalController"]),
    ]
)
