import os

internal enum AppLog {
    private static let logger = Logger(subsystem: "app.dictation", category: "App")

    static func failure(_ action: String, _ error: any Error) {
        logger.error(
            "\(action, privacy: .public) failed: \(String(describing: error), privacy: .public)"
        )
    }

    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }
}
