import Core

extension KeyBinding {
    func matchesPress(_ event: RawKeyEvent) -> Bool {
        event.trigger == trigger && event.heldModifiers == modifiers
    }

    func isShortcutKey(_ event: RawKeyEvent) -> Bool {
        guard
            event.phase == .pressed,
            case .key(let code) = event.trigger,
            code != 53,
            code != GestureRecognizer.globeCode,
            ModifierKey(rawValue: code) == nil,
            case .key(let dictateCode) = trigger,
            let held = ModifierKey(rawValue: dictateCode)?.modifier
        else { return false }
        return event.modifiers.contains(held)
    }

    func dictateMatch(for event: RawKeyEvent) -> DictateMatch? {
        guard event.trigger == trigger else { return nil }
        let held = event.heldModifiers
        if held == modifiers { return .dictate }
        if !modifiers.contains(.control), held == modifiers.union(.control) { return .edit }
        return nil
    }

    func isPlainEscape(_ event: RawKeyEvent) -> Bool {
        event.trigger == .escape && event.modifiers.subtracting(heldWhileDictating).isEmpty
    }

    private var heldWhileDictating: KeyModifiers {
        var held = modifiers.union(.control)
        if case .key(let code) = trigger, let key = ModifierKey(rawValue: code) {
            held.formUnion(key.modifier)
        }
        return held
    }
}
