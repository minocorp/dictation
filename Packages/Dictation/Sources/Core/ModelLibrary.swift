public protocol ModelLibrary: Sendable {
    func recommended() -> (speech: ModelEntry, cleanup: ModelEntry)
    func entries(stage: ModelStage) -> [ModelEntry]
    func state(of entry: ModelEntry) async -> ModelState
    func download(_ entry: ModelEntry) -> AsyncStream<DownloadEvent>
}
