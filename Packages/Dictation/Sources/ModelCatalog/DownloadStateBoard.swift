import Core
import Synchronization

internal final class DownloadStateBoard: Sendable {
    private let states = Mutex<[String: ModelState]>([:])

    func state(of id: String) -> ModelState? {
        states.withLock { $0[id] }
    }

    func set(_ state: ModelState?, for id: String) {
        states.withLock { $0[id] = state }
    }
}
