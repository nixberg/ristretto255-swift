// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "ristretto255-swift",
    products: [
        .library(
            name: "Ristretto255",
            targets: ["Ristretto255"])
    ],
    dependencies: [
        .package(url: "https://github.com/nixberg/subtle-swift", from: "0.10.0"),
    ],
    targets: [
        .target(
            name: "Ristretto255",
            dependencies: [
                .product(name: "Subtle", package: "subtle-swift"),
            ]),
        .testTarget(
            name: "Ristretto255Tests",
            dependencies: ["Ristretto255"])
    ]
)
