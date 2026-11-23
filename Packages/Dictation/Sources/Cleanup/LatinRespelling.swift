import Foundation

internal struct LatinRespelling: Sendable {
    private static let edgeMarks = CharacterSet(charactersIn: ",.?!…:;\"'()")
    private static let latinPiece = Pattern("[A-Za-z0-9]+(?:[_.#+\\-][A-Za-z0-9]+)*")
    private static let minimumHangulForPlainWord = 3
    private static let maximumHangulPerLatinLetter = 2

    func inputApplyingRespellings(input: String, output: String) -> String {
        let source = tokens(of: input)
        let target = tokens(of: output)
        guard source.contains(where: containsHangul), target.contains(where: containsLatinLetter)
        else { return input }
        var result: [String] = []
        var sourceStart = 0
        var targetStart = 0
        for (sourceAnchor, targetAnchor) in anchors(source, target) + [
            (source.count, target.count)
        ] {
            let gapSource = Array(source[sourceStart..<sourceAnchor])
            let gapTarget = Array(target[targetStart..<targetAnchor])
            result += isRespelling(of: gapSource, as: gapTarget) ? gapTarget : gapSource
            if sourceAnchor < source.count { result.append(source[sourceAnchor]) }
            sourceStart = sourceAnchor + 1
            targetStart = targetAnchor + 1
        }
        return result.joined(separator: " ")
    }

    private func tokens(of text: String) -> [String] {
        text.split(whereSeparator: \.isWhitespace).map(String.init)
    }

    private func key(_ token: String) -> String {
        token.lowercased().trimmingCharacters(in: Self.edgeMarks)
    }

    private func containsHangul(_ token: String) -> Bool {
        token.unicodeScalars.contains { $0.isHangul }
    }

    private func containsLatinLetter(_ token: String) -> Bool {
        token.unicodeScalars.contains { $0.isASCIILetter }
    }

    private func anchors(_ source: [String], _ target: [String]) -> [(Int, Int)] {
        let sourceKeys = source.map(key)
        let targetKeys = target.map(key)
        var table = Array(
            repeating: Array(repeating: 0, count: target.count + 1),
            count: source.count + 1,
        )
        for row in stride(from: source.count - 1, through: 0, by: -1) {
            for column in stride(from: target.count - 1, through: 0, by: -1) {
                table[row][column] =
                    sourceKeys[row] == targetKeys[column]
                    ? table[row + 1][column + 1] + 1
                    : max(table[row + 1][column], table[row][column + 1])
            }
        }
        var pairs: [(Int, Int)] = []
        var row = 0
        var column = 0
        while row < source.count, column < target.count {
            if sourceKeys[row] == targetKeys[column] {
                pairs.append((row, column))
                row += 1
                column += 1
            } else if table[row + 1][column] >= table[row][column + 1] {
                row += 1
            } else {
                column += 1
            }
        }
        return pairs
    }

    private func isRespelling(of source: [String], as target: [String]) -> Bool {
        guard !source.isEmpty, !target.isEmpty, !source.contains(where: containsLatinLetter) else {
            return false
        }
        let joined = target.joined(separator: " ")
        let pieces = Self.latinPiece.matchedStrings(in: joined).filter(containsLatinLetter)
        let sourceLetters = hangulLetters(in: source.joined())
        guard !pieces.isEmpty, pieces.count <= source.count,
            pieces.count * 2 >= source.count,
            pieces.allSatisfy({ isRespelledName($0, replacedLetters: sourceLetters.count) })
        else { return false }
        let remainder = hangulLetters(in: joined)
        let consumed = sourceLetters.count - remainder.count
        let latinLetters = pieces.reduce(0) { $0 + $1.count }
        return consumed <= latinLetters * Self.maximumHangulPerLatinLetter
            && isSubsequence(remainder, of: sourceLetters)
    }

    private func isRespelledName(_ piece: String, replacedLetters: Int) -> Bool {
        let token = ScriptToken(text: piece, script: .latin, offset: 0)
        let letters = piece.filter(\.isLetter)
        let isAcronym = letters.count >= 2 && letters.allSatisfy(\.isUppercase)
        let isCapitalized = piece.first?.isUppercase == true
        return token.isIdentifierLike || isAcronym
            || (isCapitalized && replacedLetters >= Self.minimumHangulForPlainWord)
    }

    private func hangulLetters(in text: String) -> [Unicode.Scalar] {
        text.unicodeScalars.filter { $0.isHangul }
    }

    private func isSubsequence(_ small: [Unicode.Scalar], of large: [Unicode.Scalar]) -> Bool {
        var cursor = large.startIndex
        for scalar in small {
            guard let found = large[cursor...].firstIndex(of: scalar) else { return false }
            cursor = large.index(after: found)
        }
        return true
    }
}
