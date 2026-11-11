// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "RuniverseWatch",
    platforms: [.watchOS(.v10)],
    products: [
        .library(name: "RuniverseWatch", targets: ["RuniverseWatch"])
    ],
    targets: [
        .target(name: "RuniverseWatch"),
        .testTarget(name: "RuniverseWatchTests", dependencies: ["RuniverseWatch"]),
    ]
)
