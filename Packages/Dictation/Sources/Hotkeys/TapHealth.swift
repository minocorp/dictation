public struct TapHealth: Hashable, Sendable {
    public let isTapEnabled: Bool
    public let isAccessibilityTrusted: Bool

    public init(isTapEnabled: Bool, isAccessibilityTrusted: Bool) {
        self.isTapEnabled = isTapEnabled
        self.isAccessibilityTrusted = isAccessibilityTrusted
    }
}
