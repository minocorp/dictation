import Core
import Foundation
import os

internal enum StoreLog {
    private static let logger = Logger(dictationCategory: "Store")

    static func failure(_ action: String, _ error: any Error) {
        logger.error(
            "\(action, privacy: .public) failed: \(String(describing: error), privacy: .public)"
        )
    }

    static func skippedRow(_ id: String) {
        logger.error("skipped unreadable row id=\(id, privacy: .public)")
    }
}
