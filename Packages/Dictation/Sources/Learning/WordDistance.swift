internal enum WordDistance {
    static func levenshtein(_ lhs: String, _ rhs: String) -> Int {
        let left = Array(lhs)
        let right = Array(rhs)
        guard !left.isEmpty else { return right.count }
        guard !right.isEmpty else { return left.count }
        var previous = Array(0...right.count)
        for (row, leftCharacter) in left.enumerated() {
            var current = [row + 1]
            for (column, rightCharacter) in right.enumerated() {
                let substitution = previous[column] + (leftCharacter == rightCharacter ? 0 : 1)
                current.append(min(substitution, previous[column + 1] + 1, current[column] + 1))
            }
            previous = current
        }
        return previous[right.count]
    }
}
