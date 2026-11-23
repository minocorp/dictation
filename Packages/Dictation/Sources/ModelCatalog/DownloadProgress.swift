import Core
import Synchronization

internal final class DownloadProgress: Sendable {
    private static let reportSteps = 1000
    private static let logSteps = 20

    private let entry: ModelEntry
    private var entryID: String { entry.id }
    private let totalBytes: Int
    private let board: DownloadStateBoard
    private let continuation: AsyncStream<DownloadEvent>.Continuation
    private let lastReported = Mutex(-1)
    private let lastLoggedStep = Mutex(-1)

    init(
        entry: ModelEntry,
        totalBytes: Int,
        board: DownloadStateBoard,
        continuation: AsyncStream<DownloadEvent>.Continuation,
    ) {
        self.entry = entry
        self.totalBytes = totalBytes
        self.board = board
        self.continuation = continuation
    }

    func report(bytesReceived: Int, force: Bool = false) {
        let step = max(totalBytes / Self.reportSteps, 1)
        let shouldReport = lastReported.withLock { last in
            guard force || bytesReceived - last >= step else { return false }
            last = bytesReceived
            return true
        }
        guard shouldReport else { return }
        logIfStepReached(bytesReceived)
        board.set(
            .downloading(bytesReceived: bytesReceived, totalBytes: totalBytes),
            for: entryID,
        )
        continuation.yield(.progress(bytesReceived: bytesReceived, totalBytes: totalBytes))
    }

    private func logIfStepReached(_ bytesReceived: Int) {
        let step = bytesReceived * Self.logSteps / max(totalBytes, 1)
        let isNewStep = lastLoggedStep.withLock { last in
            guard step > last else { return false }
            last = step
            return true
        }
        if isNewStep {
            DownloadLog.progress(entry, bytesReceived: bytesReceived, totalBytes: totalBytes)
        }
    }

    func verifying() {
        continuation.yield(.verifying)
    }
}
