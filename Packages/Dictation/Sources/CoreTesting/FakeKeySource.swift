public import Core
import Synchronization

public final class FakeKeySource: KeySource {
    private struct State {
        var startResult: Result<Void, HotkeyError> = .success(())
        var startCount = 0
        var stopCount = 0
        var policies: [TapPolicy] = []
    }

    public let events: AsyncStream<RawKeyEvent>

    private let continuation: AsyncStream<RawKeyEvent>.Continuation
    private let state = Mutex(State())

    public var startResult: Result<Void, HotkeyError> {
        get { state.withLock { $0.startResult } }
        set { state.withLock { $0.startResult = newValue } }
    }

    public var startCount: Int { state.withLock { $0.startCount } }
    public var stopCount: Int { state.withLock { $0.stopCount } }
    public var policies: [TapPolicy] { state.withLock { $0.policies } }

    public init() {
        let stream = AsyncStream.makeStream(of: RawKeyEvent.self)
        events = stream.stream
        continuation = stream.continuation
    }

    public func emit(_ event: RawKeyEvent) {
        continuation.yield(event)
    }

    public func finish() {
        continuation.finish()
    }

    public func start() throws(HotkeyError) {
        let result = state.withLock { state in
            state.startCount += 1
            return state.startResult
        }
        try result.get()
    }

    public func stop() {
        state.withLock { $0.stopCount += 1 }
    }

    public func setPolicy(_ policy: TapPolicy) {
        state.withLock { $0.policies.append(policy) }
    }
}
