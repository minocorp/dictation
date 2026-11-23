import Core
import Foundation

extension CleanupRules {
    func applyingDictionary(_ text: String, dictionary: [Word]) -> String {
        let replacements =
            dictionary.flatMap { word in
                word.soundsLike.filter { !$0.isEmpty }
                    .map { (soundAlike: $0, spelling: word.text) }
            }
            .sorted { $0.soundAlike.count > $1.soundAlike.count }
        return replacements.reduce(text) { current, replacement in
            soundAlikePattern(replacement.soundAlike)
                .replacing(in: current, with: Pattern.escapedTemplate(replacement.spelling))
        }
    }

    private func soundAlikePattern(_ soundAlike: String) -> Pattern {
        let words = soundAlike.split(whereSeparator: \.isWhitespace)
            .map { Pattern.escaped(String($0)) }
            .joined(separator: "\\s+")
        let word = "[\\p{L}\\p{N}_]"
        let endsInHangul = soundAlike.unicodeScalars.last.map(\.isHangul) ?? false
        let trailing = endsInHangul ? "" : "(?!\(word))"
        return Pattern("(?<!\(word))\(words)\(trailing)")
    }
}
