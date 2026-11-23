public import Core
import Synchronization

public final class FakeCleanupEngine: CleanupEngine {
    private struct State {
        var prepareResult: Result<Void, CleanupError> = .success(())
        var cleanResult: Result<String, CleanupError> = .success("")
        var editResult: Result<String, CleanupError> = .success("")
        var prepareCount = 0
        var unloadCount = 0
        var preheatCount = 0
        var cleanRequests: [CleanupRequest] = []
        var editRequests: [EditRequest] = []
    }

    private let state = Mutex(State())

    public var prepareResult: Result<Void, CleanupError> {
        get { state.withLock { $0.prepareResult } }
        set { state.withLock { $0.prepareResult = newValue } }
    }

    public var cleanResult: Result<String, CleanupError> {
        get { state.withLock { $0.cleanResult } }
        set { state.withLock { $0.cleanResult = newValue } }
    }

    public var editResult: Result<String, CleanupError> {
        get { state.withLock { $0.editResult } }
        set { state.withLock { $0.editResult = newValue } }
    }

    public var prepareCount: Int { state.withLock { $0.prepareCount } }
    public var unloadCount: Int { state.withLock { $0.unloadCount } }
    public var preheatCount: Int { state.withLock { $0.preheatCount } }
    public var cleanRequests: [CleanupRequest] { state.withLock { $0.cleanRequests } }
    public var editRequests: [EditRequest] { state.withLock { $0.editRequests } }

    public init() {}

    public func prepare() async throws(CleanupError) {
        let result = state.withLock { state in
            state.prepareCount += 1
            return state.prepareResult
        }
        try result.get()
    }

    public func clean(_ request: CleanupRequest) async throws(CleanupError) -> String {
        let result = state.withLock { state in
            state.cleanRequests.append(request)
            return state.cleanResult
        }
        return try result.get()
    }

    public func edit(_ request: EditRequest) async throws(CleanupError) -> String {
        let result = state.withLock { state in
            state.editRequests.append(request)
            return state.editResult
        }
        return try result.get()
    }

    public func preheat() async {
        state.withLock { $0.preheatCount += 1 }
    }

    public func unload() async {
        state.withLock { $0.unloadCount += 1 }
    }
}
