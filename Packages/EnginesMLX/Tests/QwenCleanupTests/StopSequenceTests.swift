import Cleanup
@testable import QwenCleanup
import Testing

internal struct StopSequenceTests {
    struct Case: Sendable {
        let tag: OutputTag
        let tail: String
        let isReached: Bool
    }

    static let cases = [
        Case(tag: .cleaned, tail: "다.</cleaned>", isReached: true),
        Case(tag: .cleaned, tail: "다.</clean", isReached: false),
        Case(tag: .cleaned, tail: "다.</edited>", isReached: false),
        Case(tag: .edited, tail: "done</edited>", isReached: true),
        Case(tag: .edited, tail: "done</cleaned>", isReached: false),
    ]

    @Test(arguments: cases)
    func stopIsReachedOnlyOnItsOwnClosingTag(_ example: Case) {
        let stop = StopSequence(closing: example.tag)
        #expect(stop.isReached(in: example.tail) == example.isReached)
    }

    @Test
    func budgetIsExhaustedAtTheLimit() {
        let budget = GenerationBudget(maximumTokens: 5)
        #expect(!budget.isExhausted(afterGenerating: 4))
        #expect(budget.isExhausted(afterGenerating: 5))
    }
}
