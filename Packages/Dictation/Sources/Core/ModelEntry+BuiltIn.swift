extension ModelEntry {
    public static let appleSpeechAnalyzer = builtIn(
        id: "apple-speechanalyzer",
        stage: .speech,
        displayName: "Apple Speech",
    )
    public static let appleFoundationModels = builtIn(
        id: "apple-foundation-models",
        stage: .cleanup,
        displayName: "Apple Intelligence",
    )

    private static func builtIn(id: String, stage: ModelStage, displayName: String) -> ModelEntry {
        ModelEntry(
            id: id,
            stage: stage,
            displayName: displayName,
            family: "apple",
            repo: "",
            revision: nil,
            observedRevision: nil,
            format: .builtIn,
            quant: "",
            license: "Apple",
            licenseVerified: true,
            languages: ["multilingual"],
            minRAMGB: 0,
            downloadBytes: 0,
            files: [],
            defaultFor: [.ram8],
            runtime: nil,
            verified: [],
            unverified: nil,
        )
    }
}
