public import Core

public struct CleanupBudget: Hashable, Sendable {
    public let segment: Duration
    public let edit: Duration

    public init(segment: Duration, edit: Duration) {
        self.segment = segment
        self.edit = edit
    }

    public static func recommended(for ramTier: RAMTier) -> CleanupBudget {
        switch ramTier {
        case .ram8: CleanupBudget(segment: .milliseconds(1_200), edit: .seconds(5))
        case .ram16, .ram24: CleanupBudget(segment: .milliseconds(900), edit: .seconds(5))
        }
    }
}
