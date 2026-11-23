internal struct WordToken {
    let range: Range<String.Index>
    let core: String

    static func tokens(in text: String) -> [WordToken] {
        text.split(whereSeparator: \.isWhitespace)
            .compactMap { piece in
                let core = piece.trimmingPunctuation()
                guard !core.isEmpty else { return nil }
                return WordToken(range: piece.startIndex..<piece.endIndex, core: core)
            }
    }
}

extension Substring {
    fileprivate func trimmingPunctuation() -> String {
        let isEdge: (Character) -> Bool = { $0.isPunctuation || $0.isSymbol }
        guard let start = firstIndex(where: { !isEdge($0) }) else { return "" }
        guard let last = lastIndex(where: { !isEdge($0) }) else { return "" }
        return String(self[start...last])
    }
}
