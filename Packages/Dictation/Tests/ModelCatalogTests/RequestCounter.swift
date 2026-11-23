import Foundation
import Synchronization

internal final class RequestCounter: Sendable {
    private let value = Mutex(0)

    var count: Int { value.withLock { $0 } }
    var hasRequests: Bool { value.withLock { $0 > 0 } }

    func increment() {
        value.withLock { $0 += 1 }
    }
}
