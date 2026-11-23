extension CleanupRules {
    private static let latinBeforeParticle = Pattern(
        "(?<=[A-Za-z0-9])[ ](?=(?:에서|에게|한테|으로|이랑|부터|까지|에|로|가|이|는|은|를|을|와|과|랑|의|도|만)(?![가-힣]))"
    )

    func joiningParticles(_ text: String) -> String {
        Self.latinBeforeParticle.replacing(in: text, with: "")
    }
}
