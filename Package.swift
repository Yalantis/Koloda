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
        .package(url: "https://github.com/vmzhivetyev/pop-spm-package.git", from: "1.0.4"),
    ],
    targets: [
        .target(
            name: "Koloda",
            dependencies: [.product(name: "pop", package: "pop-spm-package")],
            path: "Pod/Classes/"
        )
    ]
)
