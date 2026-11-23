import Foundation

internal struct NumberCanonicalizer: Sendable {
    private let thousandsSeparator = Pattern("(?<=\\d),(?=\\d{3}(?!\\d))")
    private let digitSeparator = Pattern("(?<=\\d)[.:,/-](?=\\d)")
    private let currencySymbols = Pattern("[$€£¥￥₩%]")
    private let digitBeforeHangul = Pattern("(?<=\\d)(?=\\p{Script=Hangul})")
    private let digitAfterHangul = Pattern("(?<=\\p{Script=Hangul})(?=\\d)")
    private let english = EnglishNumberConverter()
    private let korean = KoreanNumberConverter()

    func canonicalize(_ text: String) -> String {
        let digits = normalizingDigits(text)
        let tokens = digits.split(whereSeparator: \.isWhitespace).map(String.init)
        return korean.convert(english.convert(tokens)).joined(separator: " ")
    }

    private func normalizingDigits(_ text: String) -> String {
        let withoutThousands = thousandsSeparator.replacing(in: text, with: "")
        let separated = digitSeparator.replacing(in: withoutThousands, with: " ")
        let withoutSymbols = currencySymbols.replacing(in: separated, with: "")
        let leading = digitBeforeHangul.replacing(in: withoutSymbols, with: " ")
        return digitAfterHangul.replacing(in: leading, with: " ")
    }
}
