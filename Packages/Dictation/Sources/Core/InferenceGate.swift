import Synchronization

public final class InferenceGate: Sendable {
    private struct Waiter {
        let id: UInt64
        let continuation: CheckedContinuation<Bool, Never>
    }

    private enum Admission {
        case granted
        case denied
        case queued
    }

    private struct State {
        var isBusy = false
        var nextID: UInt64 = 0
        var waiters: [Waiter] = []
    }

    private let state = Mutex(State())

    var waiterCount: Int { state.withLock { $0.waiters.count } }

    public init() {}

    public func run<T, E: CancellableError>(
        _ work: () async throws(E) -> T
    ) async throws(E) -> T {
        guard await acquire() else { throw .cancelled }
        defer { release() }
        return try await work()
    }

    private func acquire() async -> Bool {
        let id = state.withLock { state in
            state.nextID += 1
            return state.nextID
        }
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                let admission = state.withLock { state -> Admission in
                    if Task.isCancelled { return .denied }
                    if !state.isBusy {
                        state.isBusy = true
                        return .granted
                    }
                    state.waiters.append(Waiter(id: id, continuation: continuation))
                    return .queued
                }
                switch admission {
                case .granted: continuation.resume(returning: true)
                case .denied: continuation.resume(returning: false)
                case .queued: break
                }
            }
        } onCancel: {
            let waiter = state.withLock { state -> Waiter? in
                guard let index = state.waiters.firstIndex(where: { $0.id == id }) else {
                    return nil
                }
                return state.waiters.remove(at: index)
            }
            waiter?.continuation.resume(returning: false)
        }
    }

    private func release() {
        let next = state.withLock { state -> Waiter? in
            guard !state.waiters.isEmpty else {
                state.isBusy = false
                return nil
            }
            return state.waiters.removeFirst()
        }
        next?.continuation.resume(returning: true)
    }
}
