import ApplicationServices
import Core

private let tapCallback: CGEventTapCallBack = { _, type, event, userInfo in
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let context = Unmanaged<TapContext>.fromOpaque(userInfo).takeUnretainedValue()
    return context.handle(type: type, event: event)
}

extension TapContext {
    // flagsChanged gets its own tap: Fn stops reaching a tap that also listens to key events.
    private static let eventMasks: [CGEventMask] = [
        1 << CGEventType.flagsChanged.rawValue,
        1 << CGEventType.keyDown.rawValue | 1 << CGEventType.keyUp.rawValue
            | 1 << CGEventType.otherMouseDown.rawValue | 1 << CGEventType.otherMouseUp.rawValue,
    ]

    func installTaps(userInfo: UnsafeMutableRawPointer) -> Result<Void, HotkeyError> {
        var ports: [CFMachPort] = []
        let runLoop = CFRunLoopGetCurrent()
        for mask in Self.eventMasks {
            guard
                let port = CGEvent.tapCreate(
                    tap: .cgSessionEventTap,
                    place: .headInsertEventTap,
                    options: .defaultTap,
                    eventsOfInterest: mask,
                    callback: tapCallback,
                    userInfo: userInfo,
                ),
                let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
            else {
                invalidate(ports)
                return .failure(
                    AXIsProcessTrusted() ? .eventTapUnavailable : .accessibilityNotTrusted
                )
            }
            CFRunLoopAddSource(runLoop, source, .commonModes)
            ports.append(port)
        }
        resetSwallowing()
        for port in ports { CGEvent.tapEnable(tap: port, enable: true) }
        adopt(ports)
        return .success(())
    }

    private func invalidate(_ ports: [CFMachPort]) {
        for port in ports {
            CGEvent.tapEnable(tap: port, enable: false)
            CFMachPortInvalidate(port)
        }
    }
}
