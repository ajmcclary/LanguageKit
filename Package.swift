// swift-tools-version: 6.3
import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .enableExperimentalFeature("StrictConcurrency")
]

let package = Package(
    name: "LanguageKit",
    platforms: [
        .macOS("27.0"),
        .iOS("27.0")
    ],
    products: [
        .library(name: "LanguageKit", targets: ["LanguageKit"]),
    ],
    targets: [
        .target(
            name: "LanguageKit",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "LanguageKitTests",
            dependencies: ["LanguageKit"],
            swiftSettings: swiftSettings
        ),
    ],
    swiftLanguageModes: [.v6]
)
