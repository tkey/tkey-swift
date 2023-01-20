// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "tkey_pkg",
    platforms: [
        .iOS(SupportedPlatform.IOSVersion.v15),
    ],
    products: [
        .library(
            name: "ThresholdKey",
            targets: ["tkey-pkg"]),
    ],
    dependencies: [],
    targets: [
        .binaryTarget(name: "libtkey",
                      path: "Sources/libtkey/libtkey.xcframework"
        ),
        .target(name: "lib",
               dependencies: ["libtkey"],
                path: "Sources/libtkey"
        ),
        .target(
            name: "tkey-pkg",
            dependencies: ["lib"],
            path: "Sources/ThresholdKey"
        ),
        .testTarget(
            name: "tkey-pkgTests",
            dependencies: ["tkey-pkg"],
            path: "Tests/tkeypkgTests"
        ),
    ]
)
