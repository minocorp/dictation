internal enum SmartJoiner {
    private static let sentenceEnders: Set<Character> = [".", "?", "!", "…", "。", "？", "！"]
    private static let openers: Set<Character> = [
        "(", "[", "{", "<", "“", "‘", "«", "/", "@", "#", "$", "&", "-", "_", "~", "\\",
    ]
    private static let attachingPunctuation: Set<Character> = [
        ".", ",", ";", ":", "!", "?", ")", "]", "}", ">", "%", "…", "”", "’", "»", "、", "。", "，",
        "！", "？", "：", "；", "）", "」", "』",
    ]
    private static let functionWords: Set<String> = [
        "the", "a", "an", "and", "but", "or", "so", "then", "it", "its", "this", "that", "these",
        "those", "we", "they", "he", "she", "you", "my", "our", "your", "their", "if", "when",
        "while", "because", "which", "who", "what", "how", "why", "in", "on", "at", "to", "of",
        "for", "with", "as", "is", "are", "was", "were", "be", "not", "also", "just", "there",
    ]

    static func join(_ text: String, after before: String?) -> String {
        guard let before else { return text }
        let body = String(text.drop { $0 == " " || $0 == "\t" })
        guard let first = body.first else { return text }
        guard let last = before.last else { return body }
        let separator = separator(between: last, and: first)
        return separator + adjustedCase(of: body, after: before)
    }

    private static func separator(between last: Character, and first: Character) -> String {
        if last.isNewline || last.isWhitespace || first.isNewline { return "" }
        if openers.contains(last) || attachingPunctuation.contains(first) { return "" }
        if isSpaceless(last) || isSpaceless(first) { return "" }
        return " "
    }

    private static func adjustedCase(of body: String, after before: String) -> String {
        let endsLine = before.last?.isNewline == true
        let significant = before.last { !$0.isWhitespace }
        guard let significant else { return capitalizingFirst(of: body) }
        if endsLine || sentenceEnders.contains(significant) { return capitalizingFirst(of: body) }
        return lowercasingFunctionWord(in: body)
    }

    private static func capitalizingFirst(of body: String) -> String {
        guard let first = body.first, first.isLowercase else { return body }
        let upper = first.uppercased()
        guard upper.count == 1 else { return body }
        return upper + body.dropFirst()
    }

    private static func lowercasingFunctionWord(in body: String) -> String {
        let word = body.prefix { $0.isLetter || $0 == "'" || $0 == "’" }
        guard let first = word.first, first.isUppercase else { return body }
        let rest = word.dropFirst()
        guard rest.allSatisfy({ !$0.isUppercase }), functionWords.contains(word.lowercased()) else {
            return body
        }
        return first.lowercased() + body.dropFirst()
    }

    private static let spacelessRanges: [ClosedRange<UInt32>] = [
        0x3000...0x30FF, 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xFF00...0xFFEF,
    ]

    private static func isSpaceless(_ character: Character) -> Bool {
        character.unicodeScalars.contains { scalar in
            spacelessRanges.contains { $0.contains(scalar.value) }
        }
    }
}
