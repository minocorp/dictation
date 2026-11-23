public import Core
import Foundation
import Synchronization

public final class ModelDownloader: Sendable {
    private static let safetyMarginDivisor = 10
    private static let minimumMarginBytes = 512 << 20

    private struct Job {
        let token: Int
        let task: Task<Void, Never>
    }

    private struct Registry {
        var nextToken = 0
        var jobs: [String: Job] = [:]
        var sessions: [Bool: TransferSession] = [:]
    }

    private let storage: ModelStorage
    private let sessionFactory: DownloadSessionFactory
    private let availableBytes: @Sendable () -> Int?
    private let board = DownloadStateBoard()
    private let registry = Mutex(Registry())

    public init(
        storage: ModelStorage,
        sessionFactory: DownloadSessionFactory,
        availableBytes: @escaping @Sendable () -> Int?,
    ) {
        self.storage = storage
        self.sessionFactory = sessionFactory
        self.availableBytes = availableBytes
    }

    public func state(of entry: ModelEntry) -> ModelState {
        board.state(of: entry.id) ?? (storage.isInstalled(entry) ? .ready : .notDownloaded)
    }

    public func download(
        _ entry: ModelEntry,
        allowsConstrainedNetwork: Bool,
    ) -> AsyncStream<DownloadEvent> {
        let (stream, continuation) = AsyncStream.makeStream(
            of: DownloadEvent.self,
            bufferingPolicy: .unbounded,
        )
        registry.withLock { registry in
            let previous = registry.jobs[entry.id]?.task
            previous?.cancel()
            registry.nextToken += 1
            let token = registry.nextToken
            let task = Task {
                await previous?.value
                await run(entry, allowsConstrainedNetwork, continuation)
                finishJob(entry.id, token: token)
            }
            registry.jobs[entry.id] = Job(token: token, task: task)
        }
        return stream
    }

    public func cancelDownload(of entry: ModelEntry) {
        registry.withLock { $0.jobs[entry.id]?.task.cancel() }
    }

    public func deleteFiles(of entry: ModelEntry) throws(ModelError) {
        registry.withLock { $0.jobs[entry.id]?.task.cancel() }
        board.set(nil, for: entry.id)
        try storage.delete(entry)
    }

    public func deleteFilesAfterTransferStops(of entry: ModelEntry) async throws(ModelError) {
        let running = registry.withLock { registry in
            let task = registry.jobs[entry.id]?.task
            task?.cancel()
            return task
        }
        await running?.value
        board.set(nil, for: entry.id)
        try storage.delete(entry)
    }

    private func finishJob(_ id: String, token: Int) {
        registry.withLock { registry in
            if registry.jobs[id]?.token == token { registry.jobs[id] = nil }
        }
    }

    private func session(allowsConstrainedNetwork: Bool) -> TransferSession {
        registry.withLock { registry in
            if let existing = registry.sessions[allowsConstrainedNetwork] { return existing }
            let created = TransferSession(
                configuration: sessionFactory.makeConfiguration(allowsConstrainedNetwork)
            )
            registry.sessions[allowsConstrainedNetwork] = created
            return created
        }
    }

    private func run(
        _ entry: ModelEntry,
        _ allowsConstrainedNetwork: Bool,
        _ continuation: AsyncStream<DownloadEvent>.Continuation,
    ) async {
        defer { continuation.finish() }
        let progress = DownloadProgress(
            entry: entry,
            totalBytes: entry.files.reduce(0) { $0 + $1.bytes },
            board: board,
            continuation: continuation,
        )
        do {
            try prepare(entry)
            DownloadLog.started(
                entry,
                remainingBytes: storage.remainingBytes(of: entry),
                constrainedAllowed: allowsConstrainedNetwork,
            )
            let fetcher = EntryFetcher(
                entry: entry,
                storage: storage,
                session: session(allowsConstrainedNetwork: allowsConstrainedNetwork),
                progress: progress,
            )
            let outcome = try await fetcher.fetchMissingFiles()
            DownloadLog.finished(entry, outcome: outcome)
            switch outcome {
            case .completed:
                board.set(nil, for: entry.id)
                continuation.yield(.completed)
            case .needsApproval:
                board.set(.waitingForApproval, for: entry.id)
                continuation.yield(.waitingForApproval)
            }
        } catch {
            guard error != .cancelled else {
                board.set(nil, for: entry.id)
                continuation.yield(.failed(.cancelled))
                return
            }
            DownloadLog.failed(entry, error: error)
            board.set(.failed(error), for: entry.id)
            continuation.yield(.failed(error))
        }
    }

    static func requiredBytes(withMarginFor bytes: Int) -> Int {
        bytes + bytes / safetyMarginDivisor + minimumMarginBytes
    }

    private func prepare(_ entry: ModelEntry) throws(ModelError) {
        guard entry.isDownloadable, entry.revision != nil, !entry.files.isEmpty else {
            throw .unknownModel
        }
        try storage.prepare(for: entry)
        let required = storage.remainingBytes(of: entry)
        guard let available = availableBytes() else { return }
        let needed = Self.requiredBytes(withMarginFor: required)
        guard available >= needed else {
            throw .insufficientDiskSpace(requiredBytes: needed)
        }
    }
}
