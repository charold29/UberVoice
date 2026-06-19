// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UberVoiceCore",

    // App Intents requiere iOS 16+.
    // El núcleo no depende de frameworks de Apple,
    // pero declaramos la plataforma para compatibilidad con el app target.
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

        // Lógica pura del dominio (sin dependencias externas).
        .target(
            name: "UberVoiceCore"
        ),

        // Tests del core + simulador de Siri (experimental).
        .testTarget(
            name: "UberVoiceCoreTests",
            dependencies: [
                "UberVoiceCore"
            ],
            resources: [
                .process("SiriSimulator/utterances.json")
            ]
        )
    ]
)