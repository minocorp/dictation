import Foundation

internal struct CleanupGate: Sendable {
    private static let maximumUnits = 10
    private static let maximumCharacters = 80
    private static let openListWindow = 200
    private static let edgeMarks = CharacterSet(charactersIn: ",.?!…\"'():;")

    private let matcher: CueMatcher
    private let loanwords: LoanwordSignal
    private let ambiguousFillers: [[String]]
    private let punctuationWords: Pattern
    private let numberWords: [Pattern]
    private let questionCues: [Pattern]
    private let properNounCues: [Pattern]
    private let openList = Pattern("^(\\d+\\. |- )", multiline: true)

    init(data: CueData = .standard, matcher: CueMatcher) {
        self.matcher = matcher
        loanwords = LoanwordSignal(data: data)
        ambiguousFillers = data.ambiguousFillers.all.map {
            $0.lowercased().split(separator: " ").map(String.init)
        }
        punctuationWords = Pattern(Self.punctuationSource(data.punctuationWords))
        numberWords = data.numberWords.all.map { Pattern($0) }
        questionCues = data.questionCues.all.map { Pattern($0) }
        properNounCues = data.properNounCues.map { Pattern($0) }
    }

    func decision(forRuleText text: String, contextBefore: String) -> GateDecision {
        let isSimple =
            isShort(text) && !hasCue(text) && !hasAmbiguousFiller(text)
            && !punctuationWords.contains(in: text)
            && !numberWords.contains { $0.contains(in: text) }
            && !questionCues.contains { $0.contains(in: text) }
            && !properNounCues.contains { $0.contains(in: text) }
            && !hasLineBreak(text) && !hasMixedScripts(text)
            && !loanwords.hasTransliteratedTerm(in: text)
            && !hasOpenList(contextBefore)
        return isSimple ? .skipModel : .callModel
    }

    private func hasLineBreak(_ text: String) -> Bool {
        text.contains("\n")
    }

    private func hasMixedScripts(_ text: String) -> Bool {
        let scalars = text.unicodeScalars
        return scalars.contains { $0.isHangul } && scalars.contains { $0.isASCIILetter }
    }

    private func isShort(_ text: String) -> Bool {
        text.split(whereSeparator: \.isWhitespace).count <= Self.maximumUnits
            && text.count <= Self.maximumCharacters
    }

    private func hasCue(_ text: String) -> Bool {
        matcher.hasCorrectionOrRepeat(in: text) || matcher.hasGateListCue(in: text)
    }

    private func hasOpenList(_ contextBefore: String) -> Bool {
        openList.contains(in: String(contextBefore.suffix(Self.openListWindow)))
    }

    private func hasAmbiguousFiller(_ text: String) -> Bool {
        let tokens = text.split(whereSeparator: \.isWhitespace)
            .map {
                $0.lowercased().trimmingCharacters(in: Self.edgeMarks)
            }
        return ambiguousFillers.contains { phrase in
            guard phrase.count <= tokens.count else { return false }
            return (0...(tokens.count - phrase.count))
                .contains { start in
                    Array(tokens[start..<(start + phrase.count)]) == phrase
                }
        }
    }

    private static func punctuationSource(_ words: [String]) -> String {
        let latin = words.filter { $0.unicodeScalars.allSatisfy { !$0.isHangul } }
        let hangul = words.filter { $0.unicodeScalars.contains { $0.isHangul } }
        let latinAlternatives = latin.map { $0.replacingOccurrences(of: " ", with: "\\s+") }
        return
            "\\b(?:\(latinAlternatives.joined(separator: "|")))\\b|\(hangul.joined(separator: "|"))"
    }
}
