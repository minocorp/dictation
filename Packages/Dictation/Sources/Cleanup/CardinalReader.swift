internal struct CardinalReader {
    static let units: [String: Int] = [
        "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7,
        "eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13,
        "fourteen": 14, "fifteen": 15, "sixteen": 16, "seventeen": 17, "eighteen": 18,
        "nineteen": 19,
    ]
    static let tens: [String: Int] = [
        "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50, "sixty": 60, "seventy": 70,
        "eighty": 80, "ninety": 90,
    ]
    static let scales: [String: Int] = [
        "thousand": 1000, "million": 1_000_000, "billion": 1_000_000_000,
    ]

    private enum State {
        case start
        case afterUnit
        case afterTeen
        case afterTens
        case afterHundred
        case afterScale
    }

    private var total = 0
    private var group = 0
    private var state = State.start
    private(set) var consumed = 0

    var value: Int { total + group }

    mutating func read(_ word: String, next: String?) -> Bool {
        let accepted =
            if let unit = Self.units[word] {
                readUnit(unit, word: word)
            } else if let ten = Self.tens[word] {
                readTens(ten)
            } else if word == "hundred" {
                readHundred()
            } else if let scale = Self.scales[word] {
                readScale(scale)
            } else if word == "and" {
                readAnd(next: next)
            } else {
                false
            }
        if accepted { consumed += 1 }
        return accepted
    }

    private mutating func readUnit(_ unit: Int, word: String) -> Bool {
        switch state {
        case .start, .afterHundred, .afterScale:
            if word == "zero" && state != .start { return false }
            group += unit
            state = unit < 10 ? .afterUnit : .afterTeen
            return true
        case .afterTens:
            guard (1...9).contains(unit) else { return false }
            group += unit
            state = .afterUnit
            return true
        case .afterUnit, .afterTeen:
            return false
        }
    }

    private mutating func readTens(_ ten: Int) -> Bool {
        switch state {
        case .start, .afterHundred, .afterScale:
            group += ten
            state = .afterTens
            return true
        case .afterUnit, .afterTeen, .afterTens:
            return false
        }
    }

    private mutating func readHundred() -> Bool {
        switch state {
        case .afterUnit, .afterTeen, .afterTens:
            guard (1..<100).contains(group) else { return false }
            group *= 100
            state = .afterHundred
            return true
        case .start, .afterHundred, .afterScale:
            return false
        }
    }

    private mutating func readScale(_ scale: Int) -> Bool {
        switch state {
        case .afterUnit, .afterTeen, .afterTens, .afterHundred:
            total += group * scale
            group = 0
            state = .afterScale
            return true
        case .start, .afterScale:
            return false
        }
    }

    private func readAnd(next: String?) -> Bool {
        guard state == .afterHundred || state == .afterScale, let next else { return false }
        return Self.units[next] != nil || Self.tens[next] != nil
    }
}
