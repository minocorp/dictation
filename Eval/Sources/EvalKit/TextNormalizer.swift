import Foundation

internal struct TextNormalizer {
    enum Language {
        case korean
        case english
    }

    let language: Language

    func normalized(_ text: String) -> String {
        let folded = text.precomposedStringWithCompatibilityMapping.lowercased()
        let withoutGrouping = folded.replacing(/(\d),(?=\d{3})/) { String($0.1) }
        let letters = String(
            String.UnicodeScalarView(
                withoutGrouping.unicodeScalars.map { scalar in
                    CharacterSet.alphanumerics.contains(scalar) ? scalar : " "
                }
            )
        )
        let words = letters.split(separator: " ").map(String.init)
        switch language {
        case .korean: return words.joined(separator: " ")
        case .english: return EnglishNumberWords.digits(in: words).joined(separator: " ")
        }
    }
}
