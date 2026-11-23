import Foundation

extension CleanupRules {
    private static let sentenceEnds: Set<Character> = [".", "?", "!", "…", "。", "？", "！"]
    private static let tokenBreakers: Set<Character> = ["/", ".", "_", "@"]

    func capitalizedAndEnded(_ text: String, isFinalSegment: Bool) -> String {
        let lines = text.components(separatedBy: "\n").map(capitalizedSentenceStarts)
        let cased = lines.joined(separator: "\n")
        guard isFinalSegment, shouldAppendPeriod(to: cased) else { return cased }
        return cased + "."
    }

    private func capitalizedSentenceStarts(in line: String) -> String {
        var startsSentence = true
        var tokens: [String] = []
        for token in line.split(separator: " ", omittingEmptySubsequences: true).map(String.init) {
            tokens.append(startsSentence ? capitalized(token) : token)
            startsSentence = token.last.map(Self.sentenceEnds.contains) ?? false
        }
        return tokens.joined(separator: " ")
    }

    private func capitalized(_ token: String) -> String {
        guard let first = token.first, first.isLowercase,
            first.unicodeScalars.allSatisfy(\.isASCIILetter)
        else { return token }
        let core = token.trimmingCharacters(in: CharacterSet(charactersIn: ".?!,;:…"))
        guard !core.contains(where: Self.tokenBreakers.contains),
            !core.dropFirst().contains(where: \.isUppercase)
        else { return token }
        return first.uppercased() + token.dropFirst()
    }

    private func shouldAppendPeriod(to text: String) -> Bool {
        guard let last = text.last, !Self.sentenceEnds.contains(last) else { return false }
        let unitCount = text.split(whereSeparator: \.isWhitespace).count
        let lastLine = text.components(separatedBy: "\n").last ?? ""
        return unitCount >= 2 && !isListMarker(lastLine)
    }

    private func isListMarker(_ line: String) -> Bool {
        Pattern("^\\s*(\\d+[.)]|[-*•])\\s*$").contains(in: line)
    }
}
