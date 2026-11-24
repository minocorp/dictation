import Core
import os

internal struct LogMirror: Sendable {
    private static let failureCategory = "Diagnostics"

    func write(_ level: LogLevel, _ category: String, _ message: String) {
        let logger = Logger(dictationCategory: category)
        switch level {
        case .debug: logger.debug("\(message, privacy: .public)")
        case .info: logger.info("\(message, privacy: .public)")
        case .error: logger.error("\(message, privacy: .public)")
        }
    }

    func failure(_ message: String, code: Int) {
        let logger = Logger(dictationCategory: Self.failureCategory)
        logger.error("\(message, privacy: .public) code \(code, privacy: .public)")
    }
}
