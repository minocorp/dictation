@testable import Learning
import Synchronization

internal final class FakeFieldWatcher: FieldWatching {
    private let field: FakeField?
    private let watchedPIDs = Mutex<[Int32]>([])

    var watchedPIDList: [Int32] { watchedPIDs.withLock { $0 } }

    init(field: FakeField?) {
        self.field = field
    }

    func watchFocusedField(ofPID pid: Int32) async -> (any WatchedField)? {
        watchedPIDs.withLock { $0.append(pid) }
        return field
    }
}
