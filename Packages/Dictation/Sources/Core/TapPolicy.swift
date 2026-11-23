public struct TapPolicy: Hashable, Sendable {
    public let dictateKey: KeyBinding
    public let pasteLast: KeyBinding
    public let swallowsEscape: Bool

    public init(dictateKey: KeyBinding, pasteLast: KeyBinding, swallowsEscape: Bool) {
        self.dictateKey = dictateKey
        self.pasteLast = pasteLast
        self.swallowsEscape = swallowsEscape
    }
}
