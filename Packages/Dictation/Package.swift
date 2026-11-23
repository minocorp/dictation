// swift-tools-version: 6.2

import PackageDescription

let strictSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
]

func feature(_ name: String, dependencies: [Target.Dependency] = []) -> Target {
    .target(name: name, dependencies: ["Core"] + dependencies, swiftSettings: strictSettings)
}

func tests(_ name: String, dependencies: [Target.Dependency] = []) -> Target {
    .testTarget(
        name: "\(name)Tests",
        dependencies: [.byName(name: name), "CoreTesting"] + dependencies,
        swiftSettings: strictSettings,
    )
}

let package = Package(
    name: "Dictation",
    defaultLocalization: "en",
    platforms: [.macOS(.v26)],
    products: [
        .library(
            name: "Dictation",
            targets: [
                "Core", "Hotkeys", "Capture", "Recognition", "Cleanup", "Context", "Pasteboard",
                "Insertion",
                "Learning", "Permissions", "ModelCatalog", "Store", "Diagnostics", "Session", "UI",
            ],
        ),
        .library(name: "CoreTesting", targets: ["CoreTesting"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.12.0"),
        .package(url: "https://github.com/FluidInference/FluidAudio", from: "0.18.4"),
        .package(url: "https://github.com/pointfreeco/swift-clocks", from: "1.1.1"),
    ],
    targets: [
        .target(name: "Core", swiftSettings: strictSettings),
        feature("Hotkeys"),
        feature("Capture"),
        feature(
            "Recognition",
            dependencies: [.product(name: "FluidAudio", package: "FluidAudio")],
        ),
        feature("Cleanup"),
        feature("Pasteboard"),
        feature("Context", dependencies: ["Pasteboard"]),
        feature("Insertion", dependencies: ["Pasteboard"]),
        feature("Learning"),
        feature("Permissions"),
        .target(
            name: "ModelCatalog",
            dependencies: ["Core"],
            resources: [.copy("Resources/manifest.json")],
            swiftSettings: strictSettings,
        ),
        feature("Store", dependencies: [.product(name: "GRDB", package: "GRDB.swift")]),
        feature("Diagnostics"),
        feature("Session"),
        .target(
            name: "UI",
            dependencies: ["Core", "Session"],
            resources: [.process("Resources")],
            swiftSettings: strictSettings,
        ),
        .target(
            name: "CoreTesting",
            dependencies: [
                "Core",
                "Pasteboard",
                .product(name: "Clocks", package: "swift-clocks"),
            ],
            swiftSettings: strictSettings,
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core", "CoreTesting"],
            swiftSettings: strictSettings,
        ),
        tests("Hotkeys"),
        tests("Capture"),
        tests("Recognition"),
        tests("Cleanup"),
        tests("Pasteboard"),
        tests("Context"),
        tests("Insertion"),
        tests("Learning"),
        tests("Permissions"),
        tests("ModelCatalog"),
        tests("Store"),
        tests("Diagnostics"),
        tests("Session"),
        tests("UI"),
    ],
)
