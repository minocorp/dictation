import Foundation
import Synchronization

internal final class RangeLog: Sendable {
    private let entries = Mutex<[String?]>([])

    var count: Int { entries.withLock { $0.count } }
    var values: [String?] { entries.withLock { $0 } }

    func record(_ header: String?) {
        entries.withLock { $0.append(header) }
    }
}
