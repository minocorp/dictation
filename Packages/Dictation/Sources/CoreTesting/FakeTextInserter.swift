public import Core
import Synchronization

public final class FakeTextInserter: TextInserter {
    public struct InsertCall: Hashable, Sendable {
        public let text: String
        public let target: TargetApp
        public let focus: FocusSnapshot
    }

    private struct State {
        var outcome: InsertOutcome = .inserted(.pasteShortcut)
        var calls: [InsertCall] = []
    }

    private let state = Mutex(State())

    public var outcome: InsertOutcome {
        get { state.withLock { $0.outcome } }
        set { state.withLock { $0.outcome = newValue } }
    }

    public var calls: [InsertCall] { state.withLock { $0.calls } }

    public init() {}

    public func insert(
        _ text: String,
        into target: TargetApp,
        focus: FocusSnapshot,
    ) async -> InsertOutcome {
        state.withLock { state in
            state.calls.append(InsertCall(text: text, target: target, focus: focus))
            return state.outcome
        }
    }
}
