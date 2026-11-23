public struct ApproximateTokenCounter: TokenCounting {
    private static let latinCharactersPerToken = 4

    public init() {}

    public func tokenCount(of text: String) -> Int {
        var wideCount = 0
        var narrowCount = 0
        for scalar in text.unicodeScalars where !scalar.properties.isWhitespace {
            if scalar.isHangul || scalar.value >= 0x2E80 {
                wideCount += 1
            } else {
                narrowCount += 1
            }
        }
        let narrowTokens =
            (narrowCount + Self.latinCharactersPerToken - 1) / Self.latinCharactersPerToken
        return wideCount + narrowTokens
    }
}
