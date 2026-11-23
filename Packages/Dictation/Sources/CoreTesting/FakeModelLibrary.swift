public import Core
import Synchronization

public final class FakeModelLibrary: ModelLibrary {
    private struct State {
        var recommended: (speech: ModelEntry, cleanup: ModelEntry)
        var entries: [ModelEntry]
        var states: [String: ModelState] = [:]
        var downloadScripts: [String: [DownloadEvent]] = [:]
        var downloadRequests: [String] = []
    }

    private let state: Mutex<State>

    public var downloadRequests: [String] { state.withLock { $0.downloadRequests } }

    public init(
        recommended: (speech: ModelEntry, cleanup: ModelEntry),
        entries: [ModelEntry],
    ) {
        state = Mutex(State(recommended: recommended, entries: entries))
    }

    public func setState(_ modelState: ModelState, of entry: ModelEntry) {
        state.withLock { $0.states[entry.id] = modelState }
    }

    public func setDownloadScript(_ events: [DownloadEvent], for entry: ModelEntry) {
        state.withLock { $0.downloadScripts[entry.id] = events }
    }

    public func recommended() -> (speech: ModelEntry, cleanup: ModelEntry) {
        state.withLock { $0.recommended }
    }

    public func entries(stage: ModelStage) -> [ModelEntry] {
        state.withLock { $0.entries.filter { $0.stage == stage } }
    }

    public func state(of entry: ModelEntry) async -> ModelState {
        state.withLock { $0.states[entry.id] ?? .notDownloaded }
    }

    public func download(_ entry: ModelEntry) -> AsyncStream<DownloadEvent> {
        let script = state.withLock { state in
            state.downloadRequests.append(entry.id)
            return state.downloadScripts[entry.id] ?? []
        }
        return AsyncStream { continuation in
            for event in script {
                continuation.yield(event)
            }
            continuation.finish()
        }
    }
}
