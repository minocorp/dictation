import Foundation
import Synchronization

internal final class ReceivedArguments: Sendable {
    struct Value: Equatable, Sendable {
        let id: String
        let directory: URL
    }

    private let stored = Mutex<Value?>(nil)

    var value: Value? { stored.withLock { $0 } }

    func set(id: String, directory: URL) {
        stored.withLock { $0 = Value(id: id, directory: directory) }
    }
}
