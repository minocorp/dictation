public import Core
import Synchronization

public final class FakeFocusReader: FocusReader {
    private struct State {
        var snapshotResult: FocusSnapshot?
        var selectionResult: Selection = .none
        var snapshotCount = 0
        var selectionLimits: [Int] = []
    }

    private let state = Mutex(State())

    public var snapshotResult: FocusSnapshot? {
        get { state.withLock { $0.snapshotResult } }
        set { state.withLock { $0.snapshotResult = newValue } }
    }

    public var selectionResult: Selection {
        get { state.withLock { $0.selectionResult } }
        set { state.withLock { $0.selectionResult = newValue } }
    }

    public var snapshotCount: Int { state.withLock { $0.snapshotCount } }
    public var selectionLimits: [Int] { state.withLock { $0.selectionLimits } }

    public init() {}

    public func snapshot() async -> FocusSnapshot? {
        state.withLock { state in
            state.snapshotCount += 1
            return state.snapshotResult
        }
    }

    public func selection(maxCharacters: Int) async -> Selection {
        state.withLock { state in
            state.selectionLimits.append(maxCharacters)
            return state.selectionResult
        }
    }
}
