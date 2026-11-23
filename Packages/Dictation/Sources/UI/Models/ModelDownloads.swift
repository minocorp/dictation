public import Core
import Foundation
public import Observation

@MainActor
@Observable
public final class ModelDownloads {
    public private(set) var states: [String: ModelState] = [:]
    public private(set) var verifying: Set<String> = []

    @ObservationIgnored
    private let library: any ModelLibrary
    @ObservationIgnored
    private let actions: ModelActions
    @ObservationIgnored
    private let didBecomeReady: @MainActor (ModelStage) async -> Void
    @ObservationIgnored
    private var tasks: [String: Task<Void, Never>] = [:]

    public var isDownloading: Bool {
        states.values.contains { state in
            if case .downloading = state { return true }
            return false
        }
    }

    public init(
        library: any ModelLibrary,
        actions: ModelActions,
        didBecomeReady: @escaping @MainActor (ModelStage) async -> Void,
    ) {
        self.library = library
        self.actions = actions
        self.didBecomeReady = didBecomeReady
    }

    isolated deinit {
        for task in tasks.values {
            task.cancel()
        }
    }

    public func state(of entry: ModelEntry) -> ModelState {
        guard entry.isDownloadable else { return .ready }
        return states[entry.id] ?? .notDownloaded
    }

    public func refresh() async {
        for stage in ModelStage.allCases {
            for entry in library.entries(stage: stage) where entry.isDownloadable {
                guard tasks[entry.id] == nil else { continue }
                states[entry.id] = await library.state(of: entry)
            }
        }
    }

    public func download(_ entry: ModelEntry) {
        start(entry) { library.download(entry) }
    }

    public func downloadAllowingConstrained(_ entry: ModelEntry) {
        start(entry) { actions.downloadAllowingConstrained(entry) }
    }

    public func cancel(_ entry: ModelEntry) {
        actions.cancelDownload(entry)
        tasks[entry.id]?.cancel()
        tasks[entry.id] = nil
        verifying.remove(entry.id)
        states[entry.id] = .notDownloaded
    }

    public func delete(_ entry: ModelEntry) {
        cancel(entry)
        do {
            try actions.delete(entry)
            states[entry.id] = .notDownloaded
        } catch {
            states[entry.id] = .failed(error)
        }
    }

    public func ensureDownloaded(_ entries: [ModelEntry]) {
        for entry in entries where entry.isDownloadable {
            switch state(of: entry) {
            case .notDownloaded, .failed: download(entry)
            case .waitingForApproval, .downloading, .ready: break
            }
        }
    }

    public func progress(of entries: [ModelEntry]) -> DownloadProgress? {
        var received = 0
        var total = 0
        var isActive = false
        for entry in entries where entry.isDownloadable {
            switch state(of: entry) {
            case .downloading(let bytesReceived, let totalBytes):
                received += bytesReceived
                total += totalBytes
                isActive = true
            case .ready:
                received += entry.downloadBytes
                total += entry.downloadBytes
            case .notDownloaded, .waitingForApproval, .failed:
                total += entry.downloadBytes
            }
        }
        return isActive ? DownloadProgress(receivedBytes: received, totalBytes: total) : nil
    }

    private func start(_ entry: ModelEntry, events: () -> AsyncStream<DownloadEvent>) {
        guard tasks[entry.id] == nil else { return }
        let events = events()
        states[entry.id] = .downloading(bytesReceived: 0, totalBytes: entry.downloadBytes)
        tasks[entry.id] = Task { [weak self] in
            for await event in events {
                await self?.apply(event, to: entry)
            }
            await self?.finish(entry)
        }
    }

    private func apply(_ event: DownloadEvent, to entry: ModelEntry) async {
        switch event {
        case .progress(let received, let total):
            verifying.remove(entry.id)
            states[entry.id] = .downloading(bytesReceived: received, totalBytes: total)
        case .waitingForApproval:
            states[entry.id] = .waitingForApproval
        case .verifying:
            verifying.insert(entry.id)
        case .completed:
            verifying.remove(entry.id)
            states[entry.id] = .ready
            await didBecomeReady(entry.stage)
        case .failed(let error):
            verifying.remove(entry.id)
            states[entry.id] = .failed(error)
        }
    }

    private func finish(_ entry: ModelEntry) async {
        tasks[entry.id] = nil
        guard states[entry.id] != .ready else { return }
        if case .failed = states[entry.id] { return }
        if case .waitingForApproval = states[entry.id] { return }
        states[entry.id] = await library.state(of: entry)
    }
}
