// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UberVoiceCore",
    // App Intents requiere iOS 16+. El núcleo no toca frameworks de Apple,
    // pero declaramos la plataforma para que el app target (sesión Mac) consuma
    // el package sin fricción.
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "UberVoiceCore",
            targets: ["UberVoiceCore"]
        )
    ],
    targets: [
        // Lógica pura y testeable en CI. Sin dependencias externas.
        .target(
            name: "UberVoiceCore"
        ),
        .testTarget(
            name: "UberVoiceCoreTests",
            dependencies: ["UberVoiceCore"]
        )
    ]
)
