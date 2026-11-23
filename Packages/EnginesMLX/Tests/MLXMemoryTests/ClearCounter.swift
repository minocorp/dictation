import Synchronization

internal final class ClearCounter: Sendable {
    private let value = Mutex(0)

    var total: Int { value.withLock { $0 } }

    func increment() {
        value.withLock { $0 += 1 }
    }
}
