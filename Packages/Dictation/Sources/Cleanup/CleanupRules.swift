import Core
import Foundation

internal struct CleanupRules: Sendable {
    let data: CueData
    private let specialTokens = Pattern("<\\|.*?\\|>")
    private let blankRuns = Pattern("[ \\t]+")
    private let spacesAroundNewline = Pattern(" *\\n *")
    private let blankLines = Pattern("\\n{3,}")
    private let lineCommand: Pattern
    private let paragraphCommand: Pattern

    init(data: CueData = .standard) {
        self.data = data
        lineCommand = Self.commandPattern(data.lineCommands)
        paragraphCommand = Self.commandPattern(data.paragraphCommands)
    }

    func sanitized(_ raw: String) -> String {
        let normalized = raw.precomposedStringWithCanonicalMapping
        let stripped = specialTokens.replacing(in: normalized, with: "")
        return blankRuns.replacing(in: stripped, with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func fillerFree(_ raw: String) -> String {
        writingKoreanNumbers(collapsingStutters(removingFillers(sanitized(raw))))
    }

    func ruleCleaned(_ raw: String) -> String {
        let spoken = applyingSpokenFormat(sanitized(raw))
        return writingKoreanNumbers(collapsingStutters(removingFillers(spoken)))
    }

    func finished(_ text: String, isFinalSegment: Bool, dictionary: [Word]) -> String {
        let cased = capitalizedAndEnded(text, isFinalSegment: isFinalSegment)
        return applyingDictionary(tidyingNewlines(cased), dictionary: dictionary)
    }

    func tidyingNewlines(_ text: String) -> String {
        blankLines.replacing(
            in: spacesAroundNewline.replacing(in: text, with: "\n"),
            with: "\n\n",
        )
    }

    func applyingSpokenFormat(_ text: String) -> String {
        guard hasTextBesidesCommands(text) else { return text }
        let paragraphs = paragraphCommand.replacing(in: text, with: "\n\n")
        return lineCommand.replacing(in: paragraphs, with: "\n")
    }

    private func hasTextBesidesCommands(_ text: String) -> Bool {
        let remainder = lineCommand.replacing(
            in: paragraphCommand.replacing(in: text, with: ""),
            with: "",
        )
        return remainder.unicodeScalars.contains { $0.isAlphanumeric }
    }

    private static func commandPattern(_ phrases: [String]) -> Pattern {
        let alternatives = phrases.map { $0.replacingOccurrences(of: " ", with: "\\s+") }
            .joined(separator: "|")
        let word = "[\\p{L}\\p{N}]"
        return Pattern(
            "\\s*[,.]?\\s*(?<!\(word))(?:\(alternatives))(?!\(word))\\s*[,.]?\\s*"
        )
    }
}
