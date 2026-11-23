import Foundation

internal struct TextCanonicalizer: Sendable {
    private static let joiners = Set("_./:@#+-".unicodeScalars)

    private let numbers = NumberCanonicalizer()
    private let listMarker = Pattern("^[ \\t]*(\\d+[.)]|[-*•])[ \\t]+", multiline: true)

    func canonicalText(_ text: String) -> String {
        let folded = text.precomposedStringWithCompatibilityMapping
            .replacingOccurrences(of: "’", with: "'")
        let unmarked = listMarker.replacing(in: folded, with: "")
        return numbers.canonicalize(unmarked.replacingOccurrences(of: "\n", with: " "))
    }

    func normalized(_ text: String) -> String {
        let scalars = Array(
            text.precomposedStringWithCompatibilityMapping.lowercased().unicodeScalars
        )
        var kept = String.UnicodeScalarView()
        for index in scalars.indices where isKept(scalars, at: index) {
            kept.append(scalars[index])
        }
        return String(kept)
    }

    private func isKept(_ scalars: [Unicode.Scalar], at index: Int) -> Bool {
        if scalars[index].isAlphanumeric { return true }
        return Self.joiners.contains(scalars[index]) && index > 0 && index + 1 < scalars.count
            && scalars[index - 1].isAlphanumeric && scalars[index + 1].isAlphanumeric
    }
}
