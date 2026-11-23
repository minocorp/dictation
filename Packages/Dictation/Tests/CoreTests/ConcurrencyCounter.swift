import Synchronization

internal final class ConcurrencyCounter: Sendable {
    private struct State {
        var active = 0
        var peak = 0
        var finished = 0
    }

    private let state = Mutex(State())

    var peak: Int { state.withLock { $0.peak } }
    var finished: Int { state.withLock { $0.finished } }

    func enter() {
        state.withLock { state in
            state.active += 1
            state.peak = max(state.peak, state.active)
        }
    }

    func leave() {
        state.withLock { state in
            state.active -= 1
            state.finished += 1
        }
    }
}
