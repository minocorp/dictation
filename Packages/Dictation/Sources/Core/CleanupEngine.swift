public protocol CleanupEngine: Sendable {
    func prepare() async throws(CleanupError)
    func clean(_ request: CleanupRequest) async throws(CleanupError) -> String
    func edit(_ request: EditRequest) async throws(CleanupError) -> String
    func preheat() async
    func unload() async
}
