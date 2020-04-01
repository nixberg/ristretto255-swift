// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Ristretto255",
    products: [
        .library(
            name: "Ristretto255",
            targets: ["Ristretto255"]),
    ],
    targets: [
        .target(
            name: "Ristretto255"),
        .testTarget(
            name: "Ristretto255Tests",
            dependencies: ["Ristretto255"]),
    ]
)
