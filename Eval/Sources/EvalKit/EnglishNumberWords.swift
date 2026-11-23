internal struct EnglishNumberWords {
    private static let small: [String: Int] = [
        "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7,
        "eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13,
        "fourteen": 14, "fifteen": 15, "sixteen": 16, "seventeen": 17, "eighteen": 18,
        "nineteen": 19,
    ]
    private static let tens: [String: Int] = [
        "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50, "sixty": 60, "seventy": 70,
        "eighty": 80, "ninety": 90,
    ]
    private static let scales: [String: Int] = ["thousand": 1_000, "million": 1_000_000]

    private var output: [String] = []
    private var total = 0
    private var current = 0
    private var isOpen = false
    private var pendingAnd = false

    static func digits(in words: [String]) -> [String] {
        var reader = EnglishNumberWords()
        for word in words { reader.consume(word) }
        reader.flush()
        return reader.output
    }

    private mutating func consume(_ word: String) {
        if let value = Self.small[word] ?? Self.tens[word] {
            guard canAppend(value) else {
                flush()
                return consume(word)
            }
            pendingAnd = false
            current += value
            isOpen = true
        } else if word == "hundred", isOpen, (1...99).contains(current) {
            current *= 100
            pendingAnd = false
        } else if let scale = Self.scales[word], isOpen {
            total += max(current, 1) * scale
            current = 0
            pendingAnd = false
        } else if word == "and", isOpen, !pendingAnd, current == 0 || current % 100 == 0 {
            pendingAnd = true
        } else {
            flush()
            output.append(word)
        }
    }

    private func canAppend(_ value: Int) -> Bool {
        let lastTwoDigits = current % 100
        if lastTwoDigits == 0 { return true }
        return (1...9).contains(value) && lastTwoDigits % 10 == 0
    }

    private mutating func flush() {
        if isOpen { output.append(String(total + current)) }
        if pendingAnd { output.append("and") }
        total = 0
        current = 0
        isOpen = false
        pendingAnd = false
    }
}
