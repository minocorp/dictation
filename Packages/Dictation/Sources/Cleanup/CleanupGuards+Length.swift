import Foundation

extension CleanupGuards {
    private static let edgeMarks = CharacterSet(charactersIn: ",.?!…:;\"'()")
    private static let strictDistanceRatio = 0.25
    private static let cueDistanceRatio = 0.6
    private static let absoluteDistance = 3
    private static let shortInputLength = 8

    func lengthFailure(_ context: GuardContext) -> GuardFailure? {
        let inputLength = context.normalizedInput.count
        let outputLength = context.normalizedOutput.count
        guard inputLength > 0 else { return outputLength == 0 ? nil : .lengthRatio }
        let ratio = Double(outputLength) / Double(inputLength)
        let allowed = inputLength < Self.shortInputLength ? 0.2...2.0 : 0.4...1.3
        return allowed.contains(ratio) ? nil : .lengthRatio
    }

    func editDistanceFailure(_ context: GuardContext) -> GuardFailure? {
        let input = canonicalizer.normalized(inputWithoutFillers(context.canonicalInput))
        let output = canonicalizer.normalized(
            removing(listCuePhrases, from: tokens(of: context.canonicalOutput))
                .joined(separator: " ")
        )
        let longest = max(input.count, output.count)
        guard longest > 0 else { return nil }
        let distance = EditDistance.between(input, output)
        let limit = context.hasAnyCue ? Self.cueDistanceRatio : Self.strictDistanceRatio
        let isClose =
            distance <= Self.absoluteDistance || Double(distance) / Double(longest) <= limit
        return isClose ? nil : .editDistance
    }

    private func inputWithoutFillers(_ canonical: String) -> String {
        let fillers = (data.unambiguousFillers.all + data.ambiguousFillers.all).map(phrase)
        let phrases = (fillers + listCuePhrases + data.spokenSymbolWords.map(phrase))
            .sorted { $0.count > $1.count }
        let collapsed = rules.collapsingStutters(canonical)
        return removing(phrases, from: tokens(of: collapsed)).joined(separator: " ")
    }

    private var listCuePhrases: [[String]] {
        data.listCueWords.map(phrase).sorted { $0.count > $1.count }
    }

    private func phrase(_ text: String) -> [String] {
        text.lowercased().split(separator: " ")
            .map { String($0).trimmingCharacters(in: Self.edgeMarks) }
    }

    private func tokens(of text: String) -> [String] {
        text.split(whereSeparator: \.isWhitespace).map(String.init)
    }

    private func removing(_ phrases: [[String]], from tokens: [String]) -> [String] {
        let keys = tokens.map { $0.lowercased().trimmingCharacters(in: Self.edgeMarks) }
        var kept: [String] = []
        var index = 0
        scan: while index < tokens.count {
            for phrase in phrases where index + phrase.count <= tokens.count {
                if Array(keys[index..<(index + phrase.count)]) == phrase {
                    index += phrase.count
                    continue scan
                }
            }
            kept.append(tokens[index])
            index += 1
        }
        return kept
    }
}
