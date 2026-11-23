import Foundation
import MLX
import Synchronization

package final class IdleCacheTrimmer: Sendable {
    private static let cacheLimitBytes = 128 << 20
    private static let idleDelay: Duration = .seconds(20)

    private let clock: any Clock<Duration>
    private let clear: @Sendable () -> Void
    private let pending = Mutex<Task<Void, Never>?>(nil)

    package init(
        clock: any Clock<Duration> = ContinuousClock(),
        clear: @escaping @Sendable () -> Void = { Memory.clearCache() },
    ) {
        self.clock = clock
        self.clear = clear
    }

    package func limitCache() {
        Memory.cacheLimit = Self.cacheLimitBytes
    }

    package func begin() {
        pending.withLock { task in
            task?.cancel()
            task = nil
        }
    }

    package func end() {
        let clock = clock
        let clear = clear
        pending.withLock { task in
            task?.cancel()
            task = Task {
                do {
                    try await clock.sleep(for: Self.idleDelay)
                } catch {
                    return
                }
                clear()
            }
        }
    }
}
