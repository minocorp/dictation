public import Core
import Synchronization

public final class FakePermissionMonitor: PermissionMonitor {
    private struct State {
        var requests: [Permission] = []
        var openedSettings: [Permission] = []
    }

    public let status: AsyncStream<PermissionStatus>

    private let continuation: AsyncStream<PermissionStatus>.Continuation
    private let state = Mutex(State())

    public var requests: [Permission] { state.withLock { $0.requests } }
    public var openedSettings: [Permission] { state.withLock { $0.openedSettings } }

    public init() {
        let stream = AsyncStream.makeStream(of: PermissionStatus.self)
        status = stream.stream
        continuation = stream.continuation
    }

    public func emit(_ status: PermissionStatus) {
        continuation.yield(status)
    }

    public func request(_ permission: Permission) async {
        state.withLock { $0.requests.append(permission) }
    }

    public func openSettings(for permission: Permission) async {
        state.withLock { $0.openedSettings.append(permission) }
    }
}
