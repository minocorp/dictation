import Foundation

public struct OutputParser: Sendable {
    public init() {}

    public func parse(
        _ raw: String,
        tag: OutputTag,
        reachedTokenLimit: Bool = false,
    ) -> ParsedOutput? {
        var body = Substring(raw)
        if let opening = body.range(of: tag.opening) {
            body = body[opening.upperBound...]
        }
        while true {
            let trimmed = body.drop { $0.isWhitespace }
            guard trimmed.hasPrefix(tag.opening) else { break }
            body = trimmed.dropFirst(tag.opening.count)
        }
        if let closing = body.range(of: tag.closing) {
            return ParsedOutput(text: trimmed(body[..<closing.lowerBound]), hasClosingTag: true)
        }
        let text = trimmed(body)
        guard !reachedTokenLimit, !text.isEmpty else { return nil }
        return ParsedOutput(text: text, hasClosingTag: false)
    }

    private func trimmed(_ text: Substring) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
