extension String {
    var scriptTokens: [ScriptToken] {
        ScriptTokenizer(scalars: Array(unicodeScalars)).tokens()
    }
}

private struct ScriptTokenizer {
    private static let wordMarks = Set("_./:@#+-".unicodeScalars)
    private static let trailingMarks = Set(".,:;/".unicodeScalars)

    let scalars: [Unicode.Scalar]

    func tokens() -> [ScriptToken] {
        var result: [ScriptToken] = []
        var current: [Unicode.Scalar] = []
        var currentScript: TokenScript?
        var start = 0
        var offset = 0
        for index in scalars.indices {
            let script = classify(at: index)
            if script != currentScript {
                result.append(
                    contentsOf: token(from: current, script: currentScript, offset: start)
                )
                current = []
                currentScript = script
                start = offset
            }
            if script != nil { current.append(scalars[index]) }
            offset += scalars[index].utf16.count
        }
        result.append(contentsOf: token(from: current, script: currentScript, offset: start))
        return result
    }

    private func classify(at index: Int) -> TokenScript? {
        let scalar = scalars[index]
        if scalar.isHangul { return .hangul }
        if scalar.isLatinLetter || scalar.isASCIIDigit || Self.wordMarks.contains(scalar) {
            return .latin
        }
        if scalar == "'" && isBetweenLetters(index) { return .latin }
        return scalar.isLetter ? .other : nil
    }

    private func isBetweenLetters(_ index: Int) -> Bool {
        index > 0 && index + 1 < scalars.count && scalars[index - 1].isLatinLetter
            && scalars[index + 1].isLatinLetter
    }

    private func token(
        from run: [Unicode.Scalar],
        script: TokenScript?,
        offset: Int,
    ) -> [ScriptToken] {
        guard let script, !run.isEmpty else { return [] }
        var trimmed = run[...]
        if script == .latin {
            while let last = trimmed.last, Self.trailingMarks.contains(last) {
                trimmed = trimmed.dropLast()
            }
            guard trimmed.contains(where: { $0.isLatinLetter || $0.isASCIIDigit }) else {
                return []
            }
        }
        var text = String.UnicodeScalarView()
        text.append(contentsOf: trimmed)
        return [ScriptToken(text: String(text), script: script, offset: offset)]
    }
}
