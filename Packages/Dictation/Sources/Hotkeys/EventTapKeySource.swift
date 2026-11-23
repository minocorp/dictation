public import Core
import Foundation
import Synchronization

public final class EventTapKeySource: KeySource {
    private struct Run: Sendable {
        let exited: DispatchSemaphore
        let healthTask: Task<Void, Never>
    }

    public let events: AsyncStream<RawKeyEvent>
    public let health: AsyncStream<TapHealth>

    private let context: TapContext
    private let healthContinuation: AsyncStream<TapHealth>.Continuation
    private let clock: any Clock<Duration>
    private let healthInterval: Duration
    private let running = Mutex<Run?>(nil)

    public init(
        clock: any Clock<Duration> = ContinuousClock(),
        healthInterval: Duration = .seconds(2),
    ) {
        let eventStream = AsyncStream.makeStream(of: RawKeyEvent.self)
        let healthStream = AsyncStream.makeStream(
            of: TapHealth.self,
            bufferingPolicy: .bufferingNewest(1),
        )
        events = eventStream.stream
        health = healthStream.stream
        healthContinuation = healthStream.continuation
        context = TapContext(continuation: eventStream.continuation)
        self.clock = clock
        self.healthInterval = healthInterval
    }

    deinit {
        stop()
    }

    public func start() throws(HotkeyError) {
        guard running.withLock({ $0 == nil }) else { return }
        let handshake = TapHandshake()
        let exited = DispatchSemaphore(value: 0)
        let context = context
        let thread = Thread {
            TapThread.run(context: context, handshake: handshake, exited: exited)
        }
        thread.name = "dictation.event-tap"
        thread.qualityOfService = .userInteractive
        thread.start()
        try handshake.wait().get()
        let check = TapHealthCheck(
            probe: LiveTapProbe(context: context),
            clock: clock,
            interval: healthInterval,
        )
        let continuation = healthContinuation
        let healthTask = Task { await check.run(into: continuation) }
        running.withLock { $0 = Run(exited: exited, healthTask: healthTask) }
    }

    public func stop() {
        let run = running.withLock { state in
            defer { state = nil }
            return state
        }
        guard let run else { return }
        run.healthTask.cancel()
        context.requestStop()
        run.exited.wait()
    }

    public func setCapturing(_ isCapturing: Bool) {
        context.isCapturing.withLock { $0 = isCapturing }
    }

    public func setPolicy(_ policy: TapPolicy) {
        context.policy.withLock { $0 = policy }
    }
}
