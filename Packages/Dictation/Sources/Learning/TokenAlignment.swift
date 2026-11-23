internal struct TokenAlignment {
    struct Hunk {
        let removed: [Int]
        let added: [Int]
    }

    static let cellLimit = 4_000_000

    static func hunks(from original: [String], to final: [String]) -> [Hunk]? {
        let columns = final.count + 1
        guard (original.count + 1) * columns <= cellLimit else { return nil }
        let lengths = commonLengths(original, final)
        var hunks: [Hunk] = []
        var removed: [Int] = []
        var added: [Int] = []
        var row = 0
        var column = 0
        func flush() {
            if !removed.isEmpty || !added.isEmpty {
                hunks.append(Hunk(removed: removed, added: added))
            }
            removed = []
            added = []
        }
        while row < original.count || column < final.count {
            if row < original.count, column < final.count, original[row] == final[column] {
                flush()
                row += 1
                column += 1
            } else if column < final.count,
                row == original.count
                    || lengths[row * columns + column + 1] >= lengths[(row + 1) * columns + column]
            {
                added.append(column)
                column += 1
            } else {
                removed.append(row)
                row += 1
            }
        }
        flush()
        return hunks
    }

    private static func commonLengths(_ original: [String], _ final: [String]) -> [UInt16] {
        let columns = final.count + 1
        var lengths = [UInt16](repeating: 0, count: (original.count + 1) * columns)
        for row in stride(from: original.count - 1, through: 0, by: -1) {
            for column in stride(from: final.count - 1, through: 0, by: -1) {
                lengths[row * columns + column] =
                    original[row] == final[column]
                    ? lengths[(row + 1) * columns + column + 1] + 1
                    : max(
                        lengths[(row + 1) * columns + column],
                        lengths[row * columns + column + 1],
                    )
            }
        }
        return lengths
    }
}
