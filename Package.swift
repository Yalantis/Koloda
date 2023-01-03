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
            checksum: "b7e8679f4798d1f4f52578e3843fd2e29522e39b136ceca2ffc4ecca4b221663"
        ),
    ]
)
