public protocol TokenCounting: Sendable {
    func tokenCount(of text: String) -> Int
}
