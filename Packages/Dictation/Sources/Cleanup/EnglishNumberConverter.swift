internal struct EnglishNumberConverter: Sendable {
    private struct Run {
        let tokens: [String]
        let consumed: Int
    }

    private static let digitWords: [String: Int] = [
        "oh": 0, "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6,
        "seven": 7, "eight": 8, "nine": 9,
    ]

    func convert(_ tokens: [String]) -> [String] {
        let words = tokens.map(Self.core)
        var output: [String] = []
        var index = 0
        while index < tokens.count {
            guard let run = run(at: index, words: words) else {
                output.append(tokens[index])
                index += 1
                continue
            }
            output.append(contentsOf: run.tokens)
            index += run.consumed
        }
        return output
    }

    private func run(at index: Int, words: [String?]) -> Run? {
        guard let base = digitRun(at: index, words: words) ?? cardinal(at: index, words: words)
        else { return nil }
        let pointIndex = index + base.consumed
        guard pointIndex < words.count, words[pointIndex] == "point",
            let fraction = digitRun(at: pointIndex + 1, words: words)
                ?? cardinal(at: pointIndex + 1, words: words)
        else { return base }
        return Run(
            tokens: base.tokens + fraction.tokens,
            consumed: base.consumed + 1 + fraction.consumed,
        )
    }

    private func digitRun(at index: Int, words: [String?]) -> Run? {
        var digits: [Int] = []
        var cursor = index
        while cursor < words.count, let word = words[cursor], let digit = Self.digitWords[word] {
            digits.append(digit)
            cursor += 1
        }
        let spoken = words[index..<cursor].compactMap { $0 }
        let isReadAsDigits =
            digits.count >= 2 && spoken.contains { $0 == "oh" || $0 == "zero" }
            && digits.contains { $0 != 0 }
        return isReadAsDigits ? Run(tokens: digits.map(String.init), consumed: digits.count) : nil
    }

    private func cardinal(at index: Int, words: [String?]) -> Run? {
        var reader = CardinalReader()
        var cursor = index
        while cursor < words.count, let word = words[cursor] {
            let next = cursor + 1 < words.count ? words[cursor + 1] : nil
            guard reader.read(word, next: next) else { break }
            cursor += 1
        }
        guard reader.consumed > 0, cursor > index else { return nil }
        return Run(tokens: [String(reader.value)], consumed: cursor - index)
    }

    private static func core(_ token: String) -> String? {
        let scalars = Array(token.unicodeScalars)
        guard let first = scalars.firstIndex(where: \.isLetter),
            let last = scalars.lastIndex(where: \.isLetter)
        else { return nil }
        let inner = scalars[first...last]
        guard inner.allSatisfy(\.isASCIILetter) else { return nil }
        var word = String.UnicodeScalarView()
        word.append(contentsOf: inner)
        return String(word).lowercased()
    }
}
