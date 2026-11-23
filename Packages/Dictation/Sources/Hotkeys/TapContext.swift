import ApplicationServices
import Core
import Synchronization

// CF ports and the run loop are not Sendable; they are only touched inside `lock`.
// swiftlint:disable:next no_unchecked_sendable
internal final class TapContext: @unchecked Sendable {
    let policy = Mutex<TapPolicy?>(nil)
    let isCapturing = Mutex(false)
    private let lock = Mutex(())
    private let continuation: AsyncStream<RawKeyEvent>.Continuation
    private var ports: [CFMachPort] = []
    private var runLoop: CFRunLoop?
    private var stopRequested = false
    private var swallowedTriggers: Set<KeyBinding.Trigger> = []

    init(continuation: AsyncStream<RawKeyEvent>.Continuation) {
        self.continuation = continuation
    }

    func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            reenableTaps()
            return .passUnretained(event)
        }
        guard let kind = TapInput.Kind.byEventType[type] else { return .passUnretained(event) }
        return process(TapInput(kind: kind, event: event)) ? nil : .passUnretained(event)
    }

    func process(_ input: TapInput) -> Bool {
        guard let translation = TapTranslator.translate(input) else { return false }
        let event = translation.event
        let currentPolicy = policy.withLock { $0 }
        let capturing = isCapturing.withLock { $0 }
        if capturing || currentPolicy?.isRelevant(event) ?? true, !translation.isRepeat {
            continuation.yield(event)
        }
        switch event.phase {
        case .pressed:
            let shouldSwallow =
                capturing
                ? !event.trigger.isSharedModifier
                : currentPolicy?.shouldSwallowPress(of: event) ?? false
            if shouldSwallow { swallowedTriggers.insert(event.trigger) }
            return shouldSwallow
        case .released:
            return swallowedTriggers.remove(event.trigger) != nil
        }
    }

    func resetSwallowing() {
        swallowedTriggers.removeAll()
    }

    func reenableTaps() {
        lock.withLock { _ in
            for port in ports { CGEvent.tapEnable(tap: port, enable: true) }
        }
    }

    func areTapsEnabled() -> Bool {
        lock.withLock { _ in !ports.isEmpty && ports.allSatisfy { CGEvent.tapIsEnabled(tap: $0) } }
    }

    func requestStop() {
        lock.withLock { _ in
            stopRequested = true
            if let runLoop { CFRunLoopStop(runLoop) }
        }
    }

    var isStopRequested: Bool { lock.withLock { _ in stopRequested } }

    func adopt(_ ports: [CFMachPort]) {
        lock.withLock { _ in
            self.ports = ports
            runLoop = CFRunLoopGetCurrent()
            stopRequested = false
        }
    }

    func releasePorts() {
        lock.withLock { _ in
            for port in ports {
                CGEvent.tapEnable(tap: port, enable: false)
                CFMachPortInvalidate(port)
            }
            ports = []
            runLoop = nil
        }
        resetSwallowing()
    }
}
