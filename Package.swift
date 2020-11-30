// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ristretto255-swift",
    products: [
        .library(name: "Ristretto255", targets: ["Ristretto255"])
    ],
    dependencies: [
        .package(
            name: "constant-time-swift",
            url: "https://github.com/nixberg/constant-time-swift", from: "0.1.0")
    ],
    targets: [
        .target(name: "Ristretto255", dependencies: [
            .product(name: "ConstantTime", package: "constant-time-swift")
        ]),
        .testTarget(name: "Ristretto255Tests", dependencies: ["Ristretto255"])
    ]
)
