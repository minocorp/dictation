import Foundation

public struct TextChunker: Sendable {
    public static let defaultMaximumTokens = 250

    private let counter: any TokenCounting
    private let maximumTokens: Int
    private let sentenceBreak = Pattern("(?<=[.?!…。？！])\\s+|\\n+")

    public init(
        counter: any TokenCounting = ApproximateTokenCounter(),
        maximumTokens: Int = TextChunker.defaultMaximumTokens,
    ) {
        self.counter = counter
        self.maximumTokens = maximumTokens
    }

    public func chunks(of text: String) -> [String] {
        var chunks: [String] = []
        var current = ""
        for piece in pieces(of: text) {
            if !current.isEmpty, counter.tokenCount(of: current + piece) > maximumTokens {
                chunks.append(current)
                current = ""
            }
            current += piece
        }
        chunks.append(current)
        return chunks.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func pieces(of text: String) -> [String] {
        sentences(of: text)
            .flatMap { sentence in
                counter.tokenCount(of: sentence) > maximumTokens ? words(of: sentence) : [sentence]
            }
    }

    private func sentences(of text: String) -> [String] {
        let nsText = text as NSString
        var result: [String] = []
        var cursor = 0
        for match in sentenceBreak.matches(in: text) {
            let end = match.range.location + match.range.length
            result.append(nsText.substring(with: NSRange(location: cursor, length: end - cursor)))
            cursor = end
        }
        if cursor < nsText.length { result.append(nsText.substring(from: cursor)) }
        return result
    }

    private func words(of sentence: String) -> [String] {
        var result: [String] = []
        var current = ""
        for word in sentence.split(separator: " ", omittingEmptySubsequences: false) {
            current += word + " "
            if counter.tokenCount(of: current) >= maximumTokens {
                result.append(current)
                current = ""
            }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }
}
