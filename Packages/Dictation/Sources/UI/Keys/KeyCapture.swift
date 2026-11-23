import Core

internal enum KeyCapture {
    private static let firstExtraMouseButton = 2

    static func outcome(for event: RawKeyEvent, kind: KeyRecorderKind) -> KeyCaptureOutcome {
        guard event.phase == .pressed else { return .ignored }
        return switch event.trigger {
        case .key(let code): keyOutcome(code: code, modifiers: event.modifiers, kind: kind)
        case .mouseButton(let index):
            mouseOutcome(index: index, modifiers: event.modifiers, kind: kind)
        }
    }

    private static func keyOutcome(
        code: UInt16,
        modifiers: KeyModifiers,
        kind: KeyRecorderKind,
    ) -> KeyCaptureOutcome {
        if code == 53, modifiers.isEmpty { return .cancelled }
        if let own = KeyNames.modifier(forKeyCode: code) {
            guard kind == .dictateKey else { return .ignored }
            let binding = KeyBinding(
                trigger: .key(code: code),
                modifiers: modifiers.subtracting(own),
            )
            return .accepted(binding)
        }
        guard kind == .dictateKey || !modifiers.subtracting(.function).isEmpty else {
            return .ignored
        }
        return .accepted(KeyBinding(trigger: .key(code: code), modifiers: modifiers))
    }

    private static func mouseOutcome(
        index: Int,
        modifiers: KeyModifiers,
        kind: KeyRecorderKind,
    ) -> KeyCaptureOutcome {
        guard index >= firstExtraMouseButton else { return .ignored }
        guard kind == .dictateKey || !modifiers.isEmpty else { return .ignored }
        return .accepted(KeyBinding(trigger: .mouseButton(index), modifiers: modifiers))
    }
}
