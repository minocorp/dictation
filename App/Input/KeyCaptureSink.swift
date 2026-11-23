import Core
import Synchronization

internal final class KeyCaptureSink: Sendable {
    private struct Current {
        let continuation: AsyncStream<RawKeyEvent>.Continuation
        let generation: Int
    }

    private struct State {
        var current: Current?
        var generation = 0
    }

    private let state = Mutex(State())
    private let setCapturing: @Sendable (Bool) -> Void

    init(setCapturing: @escaping @Sendable (Bool) -> Void) {
        self.setCapturing = setCapturing
    }

    func makeStream() -> AsyncStream<RawKeyEvent> {
        let (stream, continuation) = AsyncStream.makeStream(of: RawKeyEvent.self)
        let (previous, generation) = state.withLock { state in
            let previous = state.current?.continuation
            state.generation += 1
            state.current = Current(continuation: continuation, generation: state.generation)
            return (previous, state.generation)
        }
        previous?.finish()
        continuation.onTermination = { [weak self] _ in self?.didTerminate(generation) }
        setCapturing(true)
        return stream
    }

    func forward(_ event: RawKeyEvent) -> Bool {
        state.withLock { state in
            guard let current = state.current else { return false }
            current.continuation.yield(event)
            return true
        }
    }

    private func didTerminate(_ generation: Int) {
        let wasCurrent = state.withLock { state in
            guard state.current?.generation == generation else { return false }
            state.current = nil
            return true
        }
        if wasCurrent { setCapturing(false) }
    }
}
