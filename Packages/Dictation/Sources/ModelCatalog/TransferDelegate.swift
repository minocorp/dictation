import Core
import Foundation
import Synchronization

internal final class TransferDelegate: NSObject, URLSessionDownloadDelegate, Sendable {
    private enum Outcome {
        case moved
        case failed(code: Int, isOutOfSpace: Bool)
    }

    private struct Pending {
        let destination: URL
        let onProgress: @Sendable (Int) -> Void
        let continuation: CheckedContinuation<TransferResult, Never>
        var outcome: Outcome?
        var resumeData: Data?
    }

    private static let successfulStatusCodes = 200..<300

    private let pending = Mutex<[Int: Pending]>([:])

    func register(
        _ task: URLSessionTask,
        destination: URL,
        onProgress: @escaping @Sendable (Int) -> Void,
        continuation: CheckedContinuation<TransferResult, Never>,
    ) {
        pending.withLock {
            $0[task.taskIdentifier] = Pending(
                destination: destination,
                onProgress: onProgress,
                continuation: continuation,
            )
        }
    }

    func store(resumeData: Data?, for task: URLSessionTask) {
        pending.withLock { $0[task.taskIdentifier]?.resumeData = resumeData }
    }

    // swiftlint:disable:next function_parameter_count
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64,
    ) {
        let report = pending.withLock { $0[downloadTask.taskIdentifier]?.onProgress }
        report?(Int(totalBytesWritten))
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL,
    ) {
        let status = (downloadTask.response as? HTTPURLResponse)?.statusCode ?? 0
        let destination = pending.withLock { $0[downloadTask.taskIdentifier]?.destination }
        let outcome: Outcome =
            if !Self.successfulStatusCodes.contains(status) {
                .failed(code: status, isOutOfSpace: false)
            } else if let destination {
                Self.move(location, to: destination)
            } else {
                .failed(code: 0, isOutOfSpace: false)
            }
        pending.withLock { $0[downloadTask.taskIdentifier]?.outcome = outcome }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: (any Error)?,
    ) {
        guard let finished = pending.withLock({ $0.removeValue(forKey: task.taskIdentifier) })
        else {
            return
        }
        finished.continuation.resume(returning: Self.result(of: finished, error: error))
    }

    private static func move(_ source: URL, to destination: URL) -> Outcome {
        do {
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true,
            )
            try FileManager.default.moveItem(at: source, to: destination)
            return .moved
        } catch {
            return .failed(
                code: (error as NSError).code,
                isOutOfSpace: ModelError.isOutOfSpace(error),
            )
        }
    }

    private static func result(of finished: Pending, error: (any Error)?) -> TransferResult {
        if let error {
            let nsError = error as NSError
            return .failed(
                TransferFailure(
                    code: nsError.code,
                    isConstrained: (error as? URLError)?.networkUnavailableReason == .constrained,
                    isCancelled: nsError.code == NSURLErrorCancelled,
                    isOutOfSpace: ModelError.isOutOfSpace(error),
                    resumeData: finished.resumeData
                        ?? nsError.userInfo[NSURLSessionDownloadTaskResumeData] as? Data,
                )
            )
        }
        return switch finished.outcome {
        case .moved: .finished
        case .failed(let code, let isOutOfSpace):
            .failed(
                TransferFailure(
                    code: code,
                    isConstrained: false,
                    isCancelled: false,
                    isOutOfSpace: isOutOfSpace,
                    resumeData: nil,
                )
            )
        case nil:
            .failed(
                TransferFailure(
                    code: 0,
                    isConstrained: false,
                    isCancelled: false,
                    isOutOfSpace: false,
                    resumeData: nil,
                )
            )
        }
    }
}
