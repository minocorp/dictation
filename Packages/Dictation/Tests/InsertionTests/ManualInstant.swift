import Synchronization

internal final class ManualInstant: Sendable {
    private let current = Mutex(ContinuousClock.now)

    var value: ContinuousClock.Instant { current.withLock { $0 } }

    func advance(by duration: Duration) {
        current.withLock { $0 = $0.advanced(by: duration) }
    }
}
