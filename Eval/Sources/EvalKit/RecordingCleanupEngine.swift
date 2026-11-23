internal import Core
internal import Synchronization

internal final class RecordingCleanupEngine: CleanupEngine {
    struct Call: Sendable {
        let output: String?
        let duration: Duration
    }

    private let engine: any CleanupEngine
    private let calls = Mutex<[Call]>([])

    init(wrapping engine: any CleanupEngine) {
        self.engine = engine
    }

    func drain() -> [Call] {
        calls.withLock { recorded in
            defer { recorded = [] }
            return recorded
        }
    }

    func prepare() async throws(CleanupError) {
        try await engine.prepare()
    }

    func clean(_ request: CleanupRequest) async throws(CleanupError) -> String {
        try await record { () async throws(CleanupError) -> String in
            try await engine.clean(request)
        }
    }

    func edit(_ request: EditRequest) async throws(CleanupError) -> String {
        try await record { () async throws(CleanupError) -> String in
            try await engine.edit(request)
        }
    }

    func unload() async {
        await engine.unload()
    }

    private func record(
        _ work: () async throws(CleanupError) -> String
    ) async throws(CleanupError) -> String {
        let clock = ContinuousClock()
        let start = clock.now
        do {
            let output = try await work()
            calls.withLock {
                $0.append(Call(output: output, duration: start.duration(to: clock.now)))
            }
            return output
        } catch {
            calls.withLock {
                $0.append(Call(output: nil, duration: start.duration(to: clock.now)))
            }
            throw error
        }
    }
}
