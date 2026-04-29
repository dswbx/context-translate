// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ContextTranslateDiscovery",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "context-translate-discovery",
            targets: ["ContextTranslateDiscovery"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ContextTranslateDiscovery"
        )
    ]
)
