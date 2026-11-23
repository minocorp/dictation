internal protocol WatchedField: Sendable {
    var events: AsyncStream<FieldEvent> { get }
    func text() async -> String?
    func close() async
}
