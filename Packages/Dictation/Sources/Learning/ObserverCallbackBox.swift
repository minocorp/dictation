internal final class ObserverCallbackBox: Sendable {
    let continuation: AsyncStream<FieldEvent>.Continuation

    init(continuation: AsyncStream<FieldEvent>.Continuation) {
        self.continuation = continuation
    }
}
