internal enum EditDistance {
    static func between(_ lhs: String, _ rhs: String) -> Int {
        let left = Array(lhs.unicodeScalars)
        let right = Array(rhs.unicodeScalars)
        guard !left.isEmpty else { return right.count }
        guard !right.isEmpty else { return left.count }
        var previous = Array(0...right.count)
        for (row, leftScalar) in left.enumerated() {
            var current = [row + 1]
            for (column, rightScalar) in right.enumerated() {
                let substitution = previous[column] + (leftScalar == rightScalar ? 0 : 1)
                current.append(min(substitution, previous[column + 1] + 1, current[column] + 1))
            }
            previous = current
        }
        return previous[right.count]
    }
}
