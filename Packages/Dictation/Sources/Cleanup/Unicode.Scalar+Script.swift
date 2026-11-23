extension Unicode.Scalar {
    var isHangul: Bool {
        (0xAC00...0xD7AF).contains(value) || (0x1100...0x11FF).contains(value)
            || (0x3130...0x318F).contains(value) || (0xA960...0xA97F).contains(value)
            || (0xD7B0...0xD7FF).contains(value)
    }

    var isASCIILetter: Bool {
        (0x41...0x5A).contains(value) || (0x61...0x7A).contains(value)
    }

    var isASCIIDigit: Bool {
        (0x30...0x39).contains(value)
    }

    var isLetter: Bool {
        properties.isAlphabetic
    }

    var isAlphanumeric: Bool {
        isLetter || properties.numericType != nil
    }
}
