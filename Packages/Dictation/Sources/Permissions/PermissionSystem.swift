import Core
import Foundation

internal protocol PermissionSystem: Sendable {
    func microphoneAccess() -> MicrophoneAccess
    func requestMicrophoneAccess() async
    func isAccessibilityTrusted() -> Bool
    func promptForAccessibility()
    @MainActor
    func open(_ url: URL) -> Bool
}
