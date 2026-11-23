import Core

internal struct ResolvedCleanupEngine: CleanupEngine {
    let resolver: EngineResolver

    func prepare() async throws(CleanupError) {}

    func clean(_ request: CleanupRequest) async throws(CleanupError) -> String {
        try await resolver.cleanup().clean(request)
    }

    func edit(_ request: EditRequest) async throws(CleanupError) -> String {
        try await resolver.cleanup().edit(request)
    }

    func unload() async {}
}
