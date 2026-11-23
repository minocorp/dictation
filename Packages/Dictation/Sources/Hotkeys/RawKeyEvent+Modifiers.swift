import Core

extension RawKeyEvent {
    var heldModifiers: KeyModifiers {
        guard case .key(let code) = trigger, let key = ModifierKey(rawValue: code) else {
            return modifiers
        }
        return modifiers.subtracting(key.modifier)
    }
}
