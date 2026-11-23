import Foundation

internal struct LoanwordSignal: Sendable {
    private static let hangulBase: UInt32 = 0xAC00
    private static let hangulEnd: UInt32 = 0xD7A3
    private static let finalCount: UInt32 = 28
    private static let epentheticSyllables = Set("트크프브즈드그스".unicodeScalars)
    private static let closingFinals: Set<UInt32> = [1, 17, 19, 25, 26]
    private let letterNames: Pattern
    private let names: Pattern
    private let loanwordEnding = Pattern(
        "[트드브즈프크](?:에서|으로|한테|[은는이가을를의도만와과랑로에])?(?![가-힣])"
    )

    init(data: CueData = .standard) {
        letterNames = Pattern(data.letterNameAcronym)
        names = Pattern(data.transliteratedNames.joined(separator: "|"))
    }

    func hasTransliteratedTerm(in text: String) -> Bool {
        letterNames.contains(in: text) || names.contains(in: text)
            || loanwordEnding.contains(in: text)
            || hasEpenthesis(in: text)
    }

    private func hasEpenthesis(in text: String) -> Bool {
        let scalars = Array(text.unicodeScalars)
        return zip(scalars, scalars.dropFirst())
            .contains { previous, next in
                Self.epentheticSyllables.contains(next) && Self.hasClosingFinal(previous)
            }
    }

    private static func hasClosingFinal(_ scalar: Unicode.Scalar) -> Bool {
        guard (hangulBase...hangulEnd).contains(scalar.value) else { return false }
        return closingFinals.contains((scalar.value - hangulBase) % finalCount)
    }
}
