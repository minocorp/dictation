import Foundation

internal struct CueMatcher: Sendable {
    private let correctionPatterns: [Pattern]
    private let repeatPattern: Pattern
    private let ordinalPatterns: [Pattern]
    private let explicitListPatterns: [Pattern]
    private let minimumDistinctOrdinals: Int

    init(data: CueData = .standard) {
        correctionPatterns = data.correctionCues.all.map { Pattern($0) }
        repeatPattern = Pattern(data.repeatCue)
        ordinalPatterns = data.ordinalListCues.all.map { Pattern($0) }
        explicitListPatterns = data.explicitListCues.all.map { Pattern($0) }
        minimumDistinctOrdinals = data.listMinDistinctOrdinals
    }

    func lastCorrectionEnd(in text: String) -> Int? {
        let ends = (correctionPatterns + [repeatPattern])
            .flatMap { pattern in
                pattern.matches(in: text).map { $0.range.location + $0.range.length }
            }
        return ends.max()
    }

    func hasCorrectionOrRepeat(in text: String) -> Bool {
        lastCorrectionEnd(in: text) != nil
    }

    func hasAnyListCue(in text: String) -> Bool {
        explicitListPatterns.contains { $0.contains(in: text) }
            || ordinalPatterns.contains { $0.contains(in: text) }
    }

    func hasGateListCue(in text: String) -> Bool {
        explicitListPatterns.contains { $0.contains(in: text) }
            || distinctOrdinalCount(in: text) >= minimumDistinctOrdinals
    }

    private func distinctOrdinalCount(in text: String) -> Int {
        let ordinals = ordinalPatterns.flatMap { $0.matchedStrings(in: text) }
            .map { $0.lowercased().filter { !$0.isWhitespace } }
        return Set(ordinals).count
    }
}
