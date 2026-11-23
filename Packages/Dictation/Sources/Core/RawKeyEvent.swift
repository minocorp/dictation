public struct RawKeyEvent: Hashable, Sendable {
    public enum Phase: Hashable, Sendable {
        case pressed
        case released
    }

    public let phase: Phase
    public let trigger: KeyBinding.Trigger
    public let modifiers: KeyModifiers

    public init(phase: Phase, trigger: KeyBinding.Trigger, modifiers: KeyModifiers) {
        self.phase = phase
        self.trigger = trigger
        self.modifiers = modifiers
    }
}
