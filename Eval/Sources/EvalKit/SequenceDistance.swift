internal enum SequenceDistance {
    static func levenshtein<Element: Equatable>(_ left: [Element], _ right: [Element]) -> Int {
        if left.isEmpty { return right.count }
        if right.isEmpty { return left.count }
        var previous = Array(0...right.count)
        for (rowIndex, leftElement) in left.enumerated() {
            var current = [rowIndex + 1]
            for (columnIndex, rightElement) in right.enumerated() {
                let substitution = previous[columnIndex] + (leftElement == rightElement ? 0 : 1)
                current.append(
                    min(previous[columnIndex + 1] + 1, current[columnIndex] + 1, substitution)
                )
            }
            previous = current
        }
        return previous[right.count]
    }
}
