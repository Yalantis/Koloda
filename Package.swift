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
            url: "https://github.com/Wei18/pop/releases/download/1.0.12/pop.zip",
            checksum: "c950433712fff5b13bf27e190ad3143dcedf85762dbbf06efbb39058742f7434"
        ),
    ]
)
