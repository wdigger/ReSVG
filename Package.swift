// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ReSVG",
    platforms: [
        .iOS(.v15),
        .tvOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ReSVG",
            targets: ["ReSVG"]
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ReSVG",
            dependencies: ["resvgWrapper"],
        ),
        .target(
            name: "resvgWrapper",
            dependencies: ["resvg"],
            path: "Sources/resvgWrapper"
        ),
        .binaryTarget(
            name: "resvg",
            url: "https://github.com/wdigger/resvg_action/releases/download/v0.45.1/resvg.xcframework.zip",
            checksum: "f9808cbad5aff45f69f63e1b93a72639095ec8c7958b0319e09b78a20a012060"
        )
    ]
)
