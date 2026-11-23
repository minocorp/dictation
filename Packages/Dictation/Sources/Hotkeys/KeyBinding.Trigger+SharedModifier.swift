import Core

extension KeyBinding.Trigger {
    var isSharedModifier: Bool {
        guard case .key(let code) = self, let key = ModifierKey(rawValue: code) else {
            return false
        }
        return key != .function
    }
}
