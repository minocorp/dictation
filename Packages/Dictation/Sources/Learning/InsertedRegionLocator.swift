import Foundation

internal enum InsertedRegionLocator {
    static func locate(_ inserted: String, in baseline: String) -> Range<String.Index>? {
        let trimmed = inserted.trimmingCharacters(in: .whitespacesAndNewlines)
        for candidate in [trimmed, flippingFirstLetterCase(of: trimmed)] where !candidate.isEmpty {
            if let range = baseline.range(of: candidate, options: .backwards) { return range }
        }
        return nil
    }

    private static func flippingFirstLetterCase(of text: String) -> String {
        guard let first = text.first else { return text }
        let flipped = first.isUppercase ? first.lowercased() : first.uppercased()
        return flipped + text.dropFirst()
    }
}
