import Foundation

internal struct Pattern: Sendable {
    private let expression: NSRegularExpression

    init(_ source: String, caseInsensitive: Bool = true, multiline: Bool = false) {
        var options: NSRegularExpression.Options = []
        if caseInsensitive { options.insert(.caseInsensitive) }
        if multiline { options.insert(.anchorsMatchLines) }
        guard let expression = try? NSRegularExpression(pattern: source, options: options) else {
            preconditionFailure("invalid pattern \(source)")
        }
        self.expression = expression
    }

    static let numberedListMarker = Pattern("^\\s*\\d+[.)]\\s", multiline: true)

    func contains(in text: String) -> Bool {
        expression.firstMatch(in: text, range: fullRange(of: text)) != nil
    }

    func matches(in text: String) -> [NSTextCheckingResult] {
        expression.matches(in: text, range: fullRange(of: text))
    }

    func matchedStrings(in text: String) -> [String] {
        let nsText = text as NSString
        return matches(in: text).map { nsText.substring(with: $0.range) }
    }

    func firstMatchedString(in text: String) -> String? {
        matchedStrings(in: text).first
    }

    func replacing(in text: String, with template: String) -> String {
        expression.stringByReplacingMatches(
            in: text,
            range: fullRange(of: text),
            withTemplate: template,
        )
    }

    func replacing(in text: String, using transform: (String) -> String) -> String {
        let nsText = text as NSString
        var result = ""
        var cursor = 0
        for match in matches(in: text) {
            result += nsText.substring(
                with: NSRange(location: cursor, length: match.range.location - cursor)
            )
            result += transform(nsText.substring(with: match.range))
            cursor = match.range.location + match.range.length
        }
        return result + nsText.substring(from: cursor)
    }

    static func escaped(_ literal: String) -> String {
        NSRegularExpression.escapedPattern(for: literal)
    }

    static func escapedTemplate(_ literal: String) -> String {
        NSRegularExpression.escapedTemplate(for: literal)
    }

    private func fullRange(of text: String) -> NSRange {
        NSRange(location: 0, length: (text as NSString).length)
    }
}
