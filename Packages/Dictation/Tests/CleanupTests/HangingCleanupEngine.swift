import Core

internal struct HangingCleanupEngine: CleanupEngine {
    func prepare() async throws(CleanupError) {}

    func clean(_ request: CleanupRequest) async throws(CleanupError) -> String {
        try await hang()
    }

    func edit(_ request: EditRequest) async throws(CleanupError) -> String {
        try await hang()
    }

    func unload() async {}

    private func hang() async throws(CleanupError) -> String {
        let never = AsyncStream<Int> { _ in }
        for await _ in never {}
        throw .cancelled
    }
}
