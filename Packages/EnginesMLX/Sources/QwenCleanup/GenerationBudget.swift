internal struct GenerationBudget: Equatable, Sendable {
    let maximumTokens: Int

    func isExhausted(afterGenerating count: Int) -> Bool {
        count >= maximumTokens
    }
}
