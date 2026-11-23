internal enum LetterScript: CaseIterable, Hashable, Sendable {
    case hangul
    case latin
    case han
    case kana
    case cyrillic
    case other

    init?(_ scalar: Unicode.Scalar) {
        guard scalar.isLetter else { return nil }
        let value = scalar.value
        if scalar.isHangul {
            self = .hangul
        } else if scalar.isASCIILetter || (0xC0...0x24F).contains(value) {
            self = .latin
        } else if (0x4E00...0x9FFF).contains(value) || (0x3400...0x4DBF).contains(value) {
            self = .han
        } else if (0x3040...0x30FF).contains(value) {
            self = .kana
        } else if (0x0400...0x04FF).contains(value) {
            self = .cyrillic
        } else {
            self = .other
        }
    }

    static func counts(in text: String) -> [LetterScript: Int] {
        text.unicodeScalars.reduce(into: [:]) { counts, scalar in
            if let script = LetterScript(scalar) { counts[script, default: 0] += 1 }
        }
    }
}
