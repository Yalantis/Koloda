// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Koloda",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(name: "Koloda", targets: ["Koloda"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Koloda",
            dependencies: [
                "pop"
            ],
            path: "Pod/Classes/"
        ),
        .binaryTarget(
            name: "pop",
            url: "https://github.com/Wei18/pop/releases/download/1.0.12/pop-addx86sim.zip",
            checksum: "a8c00109025ef6e8d27d0a60778c2083a69f4a916ad296dac195fa8e7be77396"
        ),
    ]
)
