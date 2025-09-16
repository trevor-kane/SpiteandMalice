// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpiteandMalice",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "SpiteAndMaliceCore",
            targets: ["SpiteAndMaliceCore"]
        ),
        .executable(
            name: "SpiteAndMaliceApp",
            targets: ["SpiteAndMaliceApp"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SpiteAndMaliceCore",
            path: "Sources/SpiteAndMaliceCore"
        ),
        .executableTarget(
            name: "SpiteAndMaliceApp",
            dependencies: ["SpiteAndMaliceCore"],
            path: "Sources/SpiteAndMaliceApp",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .define("SWIFTUI_APP")
            ]
        ),
        .testTarget(
            name: "SpiteAndMaliceCoreTests",
            dependencies: ["SpiteAndMaliceCore"],
            path: "Tests/SpiteAndMaliceCoreTests"
        )
    ]
)
