// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Ristretto255",
    products: [
        .library(
            name: "Ristretto255",
            targets: ["Ristretto255"]),
    ],
    dependencies: [
        .package(name: "CTBool", url: "https://github.com/nixberg/ctbool-swift", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "Ristretto255",
            dependencies: ["CTBool"]),
        .testTarget(
            name: "Ristretto255Tests",
            dependencies: ["Ristretto255"]),
    ]
)
