// swift-tools-version: 6.2

import PackageDescription

let dictationPath = "../Packages/Dictation"

let strictSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
]

let package = Package(
    name: "Eval",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "eval", targets: ["eval"])
    ],
    dependencies: [
        .package(path: "../Packages/EnginesMLX"),
        .package(path: dictationPath),
    ],
    targets: [
        .target(
            name: "EvalKit",
            dependencies: [
                .product(name: "EnginesMLX", package: "EnginesMLX"),
                .product(name: "Dictation", package: "Dictation"),
            ],
            swiftSettings: strictSettings,
        ),
        .executableTarget(
            name: "eval",
            dependencies: ["EvalKit"],
            swiftSettings: strictSettings,
        ),
        .testTarget(
            name: "EvalKitTests",
            dependencies: ["EvalKit"],
            swiftSettings: strictSettings,
        ),
    ],
)
