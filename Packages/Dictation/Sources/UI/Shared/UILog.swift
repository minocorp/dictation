import Core
import os

internal enum UILog {
    private static let logger = Logger(dictationCategory: "UI")

    static func failure(_ action: String, _ error: any Error) {
        logger.error(
            "\(action, privacy: .public) failed: \(String(describing: error), privacy: .public)"
        )
    }
}
