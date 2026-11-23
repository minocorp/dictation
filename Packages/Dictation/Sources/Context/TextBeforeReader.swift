import Foundation

internal enum TextBeforeReader {
    static let maxCharacters = 200

    private static let replacementCharacter: Character = "\u{FFFD}"

    static func read(from element: any AccessibilityElement) -> String? {
        guard case .value(let selection) = element.range(.selectedTextRange) else { return nil }
        let start = max(0, selection.location - maxCharacters)
        let range = NSRange(location: start, length: selection.location - start)
        guard range.length > 0 else { return "" }
        guard let slice = slice(of: element, in: range) else { return nil }
        return tidy(slice)
    }

    private static func slice(of element: any AccessibilityElement, in range: NSRange) -> String? {
        if case .value(let text) = element.text(in: range) { return text }
        guard case .value(let whole) = element.string(.value) else { return nil }
        let units = Array(whole.utf16)
        guard range.location + range.length <= units.count else { return nil }
        let slice = units[range.location..<range.location + range.length]
        return String(decoding: slice, as: UTF16.self)
    }

    private static func tidy(_ slice: String) -> String {
        let withoutBrokenStart =
            slice.first == replacementCharacter ? String(slice.dropFirst()) : slice
        return String(withoutBrokenStart.suffix(maxCharacters))
    }
}
