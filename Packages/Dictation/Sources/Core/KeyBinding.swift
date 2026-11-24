public struct KeyBinding: Codable, Hashable, Sendable {
    public enum Trigger: Codable, Hashable, Sendable {
        public static let globeCode: UInt16 = 179
        public static let escape = Trigger.key(code: 53)
        public static let globe = Trigger.key(code: globeCode)

        case key(code: UInt16)
        case mouseButton(Int)
    }

    public static let fn = KeyBinding(trigger: .key(code: 63), modifiers: [])
    public static let rightOption = KeyBinding(trigger: .key(code: 61), modifiers: [])
    public static let pasteLastDefault = KeyBinding(
        trigger: .key(code: 9),
        modifiers: [.control, .command],
    )

    public let trigger: Trigger
    public let modifiers: KeyModifiers

    public init(trigger: Trigger, modifiers: KeyModifiers) {
        self.trigger = trigger
        self.modifiers = modifiers
    }
}
