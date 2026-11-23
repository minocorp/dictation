internal struct ScriptToken: Hashable, Sendable {
    let text: String
    let script: TokenScript
    let offset: Int

    var isNumber: Bool {
        script == .latin && text.unicodeScalars.allSatisfy(\.isASCIIDigit)
    }

    var isTechnicalCandidate: Bool {
        script == .latin && !isNumber
    }

    var isIdentifierLike: Bool {
        let scalars = Array(text.unicodeScalars)
        let hasInnerCapital = scalars.dropFirst().contains { $0.properties.isUppercase }
        let hasDigit = scalars.contains(where: \.isASCIIDigit)
        let hasMarker = scalars.contains { "_./:@#".unicodeScalars.contains($0) }
        return hasDigit || hasInnerCapital || hasMarker
    }

    var isTechnicalByShape: Bool {
        isIdentifierLike || text.unicodeScalars.contains { "+-".unicodeScalars.contains($0) }
    }
}
