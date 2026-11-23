internal struct ErrorRate: Equatable {
    enum Unit {
        case character
        case word
        case script
    }

    private(set) var errors = 0
    private(set) var referenceLength = 0

    var fraction: Double {
        referenceLength == 0 ? 0 : Double(errors) / Double(referenceLength)
    }

    mutating func add(reference: String, hypothesis: String, unit: Unit) {
        let referenceUnits = Self.units(of: reference, unit: unit)
        let hypothesisUnits = Self.units(of: hypothesis, unit: unit)
        errors += SequenceDistance.levenshtein(referenceUnits, hypothesisUnits)
        referenceLength += referenceUnits.count
    }

    private static func units(of text: String, unit: Unit) -> [String] {
        switch unit {
        case .character: text.filter { !$0.isWhitespace }.map(String.init)
        case .word: text.split(separator: " ").map(String.init)
        case .script: scriptUnits(of: text)
        }
    }

    private static func scriptUnits(of text: String) -> [String] {
        var units: [String] = []
        var latin = ""
        func flush() {
            if !latin.isEmpty { units.append(latin) }
            latin = ""
        }
        for character in text {
            if character.isASCII, character.isLetter || character.isNumber {
                latin.append(character)
                continue
            }
            flush()
            if character.isLetter || character.isNumber, !character.isASCII {
                units.append(String(character))
            }
        }
        flush()
        return units
    }
}
