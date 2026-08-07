// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ContextTranslatePOC",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "context-translate-poc",
            targets: ["ContextTranslateDiscovery"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ContextTranslateDiscovery"
        ),
        .testTarget(
            name: "ContextTranslateDiscoveryTests",
            dependencies: ["ContextTranslateDiscovery"]
        )
    ]
)
