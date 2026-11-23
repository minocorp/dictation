import Core
import Foundation
import Synchronization

internal final class TapHandshake: Sendable {
    private let semaphore = DispatchSemaphore(value: 0)
    private let outcome = Mutex<Result<Void, HotkeyError>>(.failure(.eventTapUnavailable))

    func complete(_ result: Result<Void, HotkeyError>) {
        outcome.withLock { $0 = result }
        semaphore.signal()
    }

    func wait() -> Result<Void, HotkeyError> {
        semaphore.wait()
        return outcome.withLock { $0 }
    }
}
