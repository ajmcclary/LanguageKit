// swift-tools-version: 6.3
import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableExperimentalFeature("StrictConcurrency")
]

let package = Package(
    name: "LanguageKit",
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
