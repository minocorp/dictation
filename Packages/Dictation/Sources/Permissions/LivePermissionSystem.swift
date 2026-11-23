import AVFoundation
import AppKit
import ApplicationServices
import Core

internal struct LivePermissionSystem: PermissionSystem {
    func microphoneAccess() -> MicrophoneAccess {
        switch AVAudioApplication.shared.recordPermission {
        case .undetermined: .notDetermined
        case .granted: .granted
        case .denied: .denied
        @unknown default: .notDetermined
        }
    }

    func requestMicrophoneAccess() async {
        _ = await AVAudioApplication.requestRecordPermission()
    }

    func isAccessibilityTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    func promptForAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    @MainActor
    func open(_ url: URL) -> Bool {
        NSWorkspace.shared.open(url)
    }
}
