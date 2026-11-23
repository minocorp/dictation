import Foundation
import Synchronization

internal final class TransferSession: Sendable {
    private let session: URLSession
    private let delegate: TransferDelegate

    init(configuration: URLSessionConfiguration) {
        let delegate = TransferDelegate()
        self.delegate = delegate
        session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }

    deinit {
        session.finishTasksAndInvalidate()
    }

    func download(
        from url: URL,
        resumeData: Data?,
        to destination: URL,
        onProgress: @escaping @Sendable (Int) -> Void,
    ) async -> TransferResult {
        let started = Mutex<URLSessionDownloadTask?>(nil)
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                let task =
                    resumeData.map { session.downloadTask(withResumeData: $0) }
                    ?? session.downloadTask(with: url)
                delegate.register(
                    task,
                    destination: destination,
                    onProgress: onProgress,
                    continuation: continuation,
                )
                started.withLock { $0 = task }
                if Task.isCancelled {
                    task.cancel()
                } else {
                    task.resume()
                }
            }
        } onCancel: {
            guard let task = started.withLock({ $0 }) else { return }
            task.cancel(byProducingResumeData: { [delegate] data in
                delegate.store(resumeData: data, for: task)
            })
        }
    }
}
