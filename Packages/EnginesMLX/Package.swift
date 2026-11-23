// swift-tools-version: 6.2

import PackageDescription

let dictationPath = "../Dictation"

let strictSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
]

let package = Package(
    name: "EnginesMLX",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "EnginesMLX", targets: ["QwenASR", "QwenCleanup"])
    ],
    dependencies: [
        .package(path: dictationPath),
        .package(url: "https://github.com/ml-explore/mlx-swift", .upToNextMinor(from: "0.33.0")),
        .package(url: "https://github.com/ml-explore/mlx-swift-lm", exact: "3.33.0"),
        .package(url: "https://github.com/Blaizzy/mlx-audio-swift", exact: "0.2.1"),
        .package(url: "https://github.com/huggingface/swift-huggingface", from: "1.0.1"),
        .package(url: "https://github.com/huggingface/swift-transformers", from: "1.4.0"),
    ],
    targets: [
        .target(
            name: "MLXMemory",
            dependencies: [.product(name: "MLX", package: "mlx-swift")],
            swiftSettings: strictSettings,
        ),
        .target(
            name: "QwenASR",
            dependencies: [
                "MLXMemory",
                .product(name: "Dictation", package: "Dictation"),
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXAudioSTT", package: "mlx-audio-swift"),
            ],
            swiftSettings: strictSettings,
        ),
        .target(
            name: "TokenizerBridge",
            dependencies: [
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
                .product(name: "MLXHuggingFace", package: "mlx-swift-lm"),
                .product(name: "HuggingFace", package: "swift-huggingface"),
                .product(name: "Tokenizers", package: "swift-transformers"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("InternalImportsByDefault"),
                .enableUpcomingFeature("MemberImportVisibility"),
            ],
        ),
        .target(
            name: "QwenCleanup",
            dependencies: [
                "TokenizerBridge",
                "MLXMemory",
                .product(name: "Dictation", package: "Dictation"),
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
                .product(name: "MLXHuggingFace", package: "mlx-swift-lm"),
                .product(name: "HuggingFace", package: "swift-huggingface"),
                .product(name: "Tokenizers", package: "swift-transformers"),
            ],
            swiftSettings: strictSettings,
        ),
        .testTarget(
            name: "MLXMemoryTests",
            dependencies: [
                "MLXMemory",
                .product(name: "CoreTesting", package: "Dictation"),
            ],
            swiftSettings: strictSettings,
        ),
        .testTarget(
            name: "QwenASRTests",
            dependencies: [
                "QwenASR",
                .product(name: "CoreTesting", package: "Dictation"),
            ],
            swiftSettings: strictSettings,
        ),
        .testTarget(
            name: "QwenCleanupTests",
            dependencies: [
                "QwenCleanup",
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
                .product(name: "CoreTesting", package: "Dictation"),
            ],
            swiftSettings: strictSettings,
        ),
    ],
)
