@testable import Cleanup
import Core
import Testing

internal struct CleanupBudgetTests {
    struct BudgetCase: Sendable {
        let tier: RAMTier
        let segment: Duration
    }

    static let budgets = [
        BudgetCase(tier: .ram8, segment: .milliseconds(1_200)),
        BudgetCase(tier: .ram16, segment: .milliseconds(900)),
        BudgetCase(tier: .ram24, segment: .milliseconds(900)),
    ]

    @Test(arguments: budgets)
    func budgetFollowsRAMTier(_ example: BudgetCase) {
        let budget = CleanupBudget.recommended(for: example.tier)
        #expect(budget == CleanupBudget(segment: example.segment, edit: .seconds(5)))
    }
}
