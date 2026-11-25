import Core
import Foundation
import os

internal enum DownloadLog {
    private static let logger = Logger(dictationCategory: "models")

    static func started(_ entry: ModelEntry, remainingBytes: Int, constrainedAllowed: Bool) {
        logger.info(
            "download started id=\(entry.id, privacy: .public) remaining=\(remainingBytes) constrainedAllowed=\(constrainedAllowed)"
        )
    }

    static func fileStarted(_ file: ModelFile, of entry: ModelEntry, resuming: Bool) {
        logger.info(
            "file started id=\(entry.id, privacy: .public) path=\(file.path, privacy: .public) bytes=\(file.bytes) resuming=\(resuming)"
        )
    }

    static func fileInstalled(_ file: ModelFile, of entry: ModelEntry) {
        logger.info(
            "file installed id=\(entry.id, privacy: .public) path=\(file.path, privacy: .public)"
        )
    }

    static func progress(_ entry: ModelEntry, bytesReceived: Int, totalBytes: Int) {
        logger.info(
            "progress id=\(entry.id, privacy: .public) received=\(bytesReceived) total=\(totalBytes)"
        )
    }

    static func transferFailed(_ file: ModelFile, of entry: ModelEntry, code: Int) {
        logger.error(
            "transfer failed id=\(entry.id, privacy: .public) path=\(file.path, privacy: .public) code=\(code)"
        )
    }

    static func finished(_ entry: ModelEntry, outcome: FetchOutcome) {
        logger.info(
            "download finished id=\(entry.id, privacy: .public) outcome=\(String(describing: outcome), privacy: .public)"
        )
    }

    static func failed(_ entry: ModelEntry, error: ModelError) {
        logger.error(
            "download failed id=\(entry.id, privacy: .public) error=\(String(describing: error), privacy: .public)"
        )
    }

    static func stampFailed(_ entry: ModelEntry, error: any Error) {
        logger.error(
            "stamp write failed id=\(entry.id, privacy: .public) error=\(String(describing: error), privacy: .public)"
        )
    }
}
