import Core
import Foundation
import Synchronization

internal final class CaptureControl: Sendable {
    private struct Flags {
        var isStopRequested = false
        var hasRouteChanged = false
    }

    private let opened = DispatchSemaphore(value: 0)
    private let finished = DispatchSemaphore(value: 0)

    private let flags = Mutex(Flags())
    private let openResult = Mutex<Result<Void, CaptureError>?>(nil)

    var isStopRequested: Bool { flags.withLock { $0.isStopRequested } }

    var openOutcome: Result<Void, CaptureError> {
        openResult.withLock { $0 } ?? .failure(.engineFailed(code: 0))
    }

    func requestStop() {
        flags.withLock { $0.isStopRequested = true }
    }

    func noteRouteChange() {
        flags.withLock { $0.hasRouteChanged = true }
    }

    func consumeRouteChange() -> Bool {
        flags.withLock { flags in
            defer { flags.hasRouteChanged = false }
            return flags.hasRouteChanged
        }
    }

    func reportOpened(_ result: Result<Void, CaptureError>) {
        openResult.withLock { $0 = result }
        opened.signal()
    }

    func reportFinished() {
        finished.signal()
    }

    func waitUntilOpened() async {
        await Self.wait(on: opened)
    }

    func waitUntilFinished() async {
        await Self.wait(on: finished)
    }

    private static func wait(on semaphore: DispatchSemaphore) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated)
                .async {
                    semaphore.wait()
                    continuation.resume()
                }
        }
    }
}
