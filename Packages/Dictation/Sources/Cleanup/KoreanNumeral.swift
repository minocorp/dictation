internal struct KoreanNumeral: Hashable, Sendable {
    let digits: String
    let source: String
    let isNative: Bool

    var syllableCount: Int { source.count }

    var isDigitSequence: Bool {
        !isNative && source.allSatisfy { Self.sinoDigits[$0] != nil }
    }

    private static let sinoDigits: [Character: Int] = [
        "영": 0, "공": 0, "일": 1, "이": 2, "삼": 3, "사": 4, "오": 5, "육": 6, "칠": 7, "팔": 8,
        "구": 9,
    ]
    private static let smallUnits: [Character: Int] = ["십": 10, "백": 100, "천": 1000]
    private static let groupUnits: [Character: Int] = [
        "만": 10_000, "억": 100_000_000, "조": 1_000_000_000_000,
    ]
    private static let nativeUnits: [(word: String, value: Int)] = [
        ("하나", 1), ("다섯", 5), ("여섯", 6), ("일곱", 7), ("여덟", 8), ("아홉", 9), ("한", 1),
        ("둘", 2), ("두", 2), ("셋", 3), ("세", 3), ("석", 3), ("서", 3), ("넷", 4), ("네", 4),
        ("넉", 4), ("너", 4),
    ]
    private static let nativeTens: [(word: String, value: Int)] = [
        ("스물", 20), ("스무", 20), ("서른", 30), ("마흔", 40), ("예순", 60), ("일흔", 70),
        ("여든", 80), ("아흔", 90), ("열", 10), ("쉰", 50),
    ]

    static func parse(_ source: String) -> KoreanNumeral? {
        if let digits = sino(Array(source)) {
            return KoreanNumeral(digits: digits, source: source, isNative: false)
        }
        guard let value = native(source) else { return nil }
        return KoreanNumeral(digits: String(value), source: source, isNative: true)
    }

    private static func sino(_ characters: [Character]) -> String? {
        guard !characters.isEmpty else { return nil }
        let hasUnit = characters.contains { smallUnits[$0] != nil || groupUnits[$0] != nil }
        return hasUnit ? positional(characters) : digitSequence(characters)
    }

    private static func digitSequence(_ characters: [Character]) -> String? {
        let digits = characters.compactMap { sinoDigits[$0] }
        guard digits.count == characters.count, digits.count != 2 else { return nil }
        return digits.map(String.init).joined()
    }

    private static func positional(_ characters: [Character]) -> String? {
        var total = 0
        var section = 0
        var pending: Int?
        for character in characters {
            if let digit = sinoDigits[character] {
                guard pending == nil else { return nil }
                pending = digit
            } else if let unit = smallUnits[character] {
                section += (pending ?? 1) * unit
                pending = nil
            } else if let group = groupUnits[character] {
                section += pending ?? 0
                total += (section == 0 ? 1 : section) * group
                section = 0
                pending = nil
            } else {
                return nil
            }
        }
        return String(total + section + (pending ?? 0))
    }

    private static func native(_ source: String) -> Int? {
        var rest = Substring(source)
        var value = 0
        var matched = false
        if let tens = nativeTens.first(where: { rest.hasPrefix($0.word) }) {
            rest = rest.dropFirst(tens.word.count)
            value += tens.value
            matched = true
        }
        if let unit = nativeUnits.first(where: { rest.hasPrefix($0.word) }) {
            rest = rest.dropFirst(unit.word.count)
            value += unit.value
            matched = true
        }
        return matched && rest.isEmpty ? value : nil
    }
}
