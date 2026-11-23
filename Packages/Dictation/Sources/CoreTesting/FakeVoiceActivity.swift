public import Core
import Synchronization

public final class FakeVoiceActivity: VoiceActivity {
    private struct State {
        var requestedIDs: [DictationID] = []
        var continuation: AsyncStream<Segment>.Continuation?
    }

    private let state = Mutex(State())

    public var requestedIDs: [DictationID] { state.withLock { $0.requestedIDs } }

    public init() {}

    public func emit(_ segment: Segment) {
        let continuation = state.withLock { $0.continuation }
        continuation?.yield(segment)
    }

    public func finish() {
        let continuation = state.withLock { $0.continuation }
        continuation?.finish()
    }

    public func segments(
        of chunks: AsyncStream<AudioChunk>,
        id: DictationID,
    ) -> AsyncStream<Segment> {
        let stream = AsyncStream.makeStream(of: Segment.self)
        state.withLock { state in
            state.requestedIDs.append(id)
            state.continuation = stream.continuation
        }
        return stream.stream
    }
}
