import ApplicationServices

internal struct TapInput: Equatable, Sendable {
    enum Kind: Hashable, Sendable {
        case keyDown
        case keyUp
        case flagsChanged
        case mouseDown
        case mouseUp

        static let byEventType: [CGEventType: Kind] = [
            .keyDown: .keyDown,
            .keyUp: .keyUp,
            .flagsChanged: .flagsChanged,
            .otherMouseDown: .mouseDown,
            .otherMouseUp: .mouseUp,
        ]
    }

    let kind: Kind
    let keyCode: UInt16
    let flags: CGEventFlags
    let mouseButton: Int
    let isRepeat: Bool
}

extension TapInput {
    init(kind: Kind, event: CGEvent) {
        self.init(
            kind: kind,
            keyCode: UInt16(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode)),
            flags: event.flags,
            mouseButton: Int(event.getIntegerValueField(.mouseEventButtonNumber)),
            isRepeat: event.getIntegerValueField(.keyboardEventAutorepeat) != 0,
        )
    }
}
