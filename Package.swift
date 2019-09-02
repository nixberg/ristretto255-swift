// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Ristretto255",
    products: [
        .library(
            name: "Ristretto255",
            targets: ["Ristretto255"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Ristretto255",
            dependencies: []),
        .testTarget(
            name: "Ristretto255Tests",
            dependencies: ["Ristretto255"]),
    ]
)
