public import Core

public protocol CleanupPipeline: Sendable {
    func clean(_ input: CleanInput, dictionary: [Word]) async throws(CleanupError) -> String
    func edit(selection: String, instruction: String) async throws(CleanupError) -> String
}
