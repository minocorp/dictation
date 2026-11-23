@testable import Hotkeys
import Synchronization

internal final class ScriptedTapProbe: TapProbe {
    private struct State {
        var health: TapHealth
        var readCount = 0
    }

    private let state: Mutex<State>

    var readCount: Int { state.withLock { $0.readCount } }

    init(_ health: TapHealth) {
        state = Mutex(State(health: health))
    }

    func set(_ health: TapHealth) {
        state.withLock { $0.health = health }
    }

    func read() -> TapHealth {
        state.withLock { state in
            state.readCount += 1
            return state.health
        }
    }
}
