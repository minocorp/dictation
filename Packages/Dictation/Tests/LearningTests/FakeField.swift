@testable import Learning
import Synchronization

internal final class FakeField: WatchedField {
    private struct State {
        var texts: [String?]
        var isClosed = false
    }

    let events: AsyncStream<FieldEvent>
    private let continuation: AsyncStream<FieldEvent>.Continuation
    private let state: Mutex<State>

    var isClosed: Bool { state.withLock { $0.isClosed } }

    init(texts: [String?], events: [FieldEvent]) {
        let (stream, continuation) = AsyncStream.makeStream(of: FieldEvent.self)
        self.events = stream
        self.continuation = continuation
        state = Mutex(State(texts: texts))
        for event in events { continuation.yield(event) }
    }

    func text() async -> String? {
        state.withLock { state in
            guard state.texts.count > 1 else { return state.texts.first ?? nil }
            return state.texts.removeFirst()
        }
    }

    func close() async {
        state.withLock { $0.isClosed = true }
        continuation.finish()
    }
}
