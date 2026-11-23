import Foundation

extension CleanupRules {
    private static let trailingMarks = CharacterSet(charactersIn: ",.…")
    private static let maximumStutterLength = 1

    func removingFillers(_ text: String) -> String {
        mapTokens(in: text) { tokens in
            tokens.filter { !isUnambiguousFiller($0) }
        }
    }

    func writingKoreanNumbers(_ text: String) -> String {
        mapTokens(in: text) { KoreanNumberConverter().formatted($0) }
    }

    func collapsingStutters(_ text: String) -> String {
        mapTokens(in: text) { tokens in
            var kept: [String] = []
            for token in tokens {
                if let previous = kept.last, isStutter(previous, token) {
                    kept.removeLast()
                }
                kept.append(token)
            }
            return kept
        }
    }

    func mapTokens(in text: String, transform: ([String]) -> [String]) -> String {
        text.components(separatedBy: "\n")
            .map { line in
                transform(
                    line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
                )
                .joined(separator: " ")
            }
            .joined(separator: "\n")
    }

    private func isUnambiguousFiller(_ token: String) -> Bool {
        let lowered = token.lowercased()
        let core = strippingTrailingMarks(lowered)
        let hasTrailingDots = lowered.contains(".") || lowered.contains("…")
        return data.unambiguousFillers.all.contains { entry in
            let entryCore = entry.trimmingCharacters(in: Self.trailingMarks)
            let requiresDots = entry != entryCore
            return core == entryCore && (!requiresDots || hasTrailingDots)
        }
    }

    private func strippingTrailingMarks(_ text: String) -> String {
        var scalars = Substring(text).unicodeScalars
        while let last = scalars.last, Self.trailingMarks.contains(last) {
            scalars = scalars.dropLast()
        }
        return String(scalars)
    }

    private func isStutter(_ previous: String, _ token: String) -> Bool {
        let key = stutterKey(token)
        guard key == stutterKey(previous) else { return false }
        guard key.allSatisfy(\.isLetter) else { return false }
        return key.count <= Self.maximumStutterLength || data.stutterWords.contains(key)
    }

    private func stutterKey(_ token: String) -> String {
        token.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ","))
    }
}
