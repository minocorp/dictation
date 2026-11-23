public struct PermissionStatus: Hashable, Sendable {
    public let microphone: MicrophoneAccess
    public let isAccessibilityTrusted: Bool

    public init(microphone: MicrophoneAccess, isAccessibilityTrusted: Bool) {
        self.microphone = microphone
        self.isAccessibilityTrusted = isAccessibilityTrusted
    }
}
