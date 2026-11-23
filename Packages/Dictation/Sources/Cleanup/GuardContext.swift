import Core

internal struct GuardContext {
    let input: String
    let spokenInput: String
    let output: String
    let dictionary: [Word]
    let canonicalInput: String
    let canonicalOutput: String
    let normalizedInput: String
    let normalizedOutput: String
    let inputTokens: [ScriptToken]
    let outputTokens: [ScriptToken]
    let lastCueEnd: Int?
    let hasAnyCue: Bool

    var isHangulHeavy: Bool {
        let counts = LetterScript.counts(in: canonicalInput)
        let total = counts.values.reduce(0, +)
        return total > 0 && Double(counts[.hangul, default: 0]) / Double(total) >= 0.3
    }

    var dictionaryTexts: Set<String> { Set(dictionary.map(\.text)) }
}
