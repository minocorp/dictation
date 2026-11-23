import Synchronization

internal final class Recorder: Sendable {
    private let storage = Mutex<[Int]>([])

    var values: [Int] { storage.withLock { $0 } }

    func append(_ value: Int) {
        storage.withLock { $0.append(value) }
    }
}
