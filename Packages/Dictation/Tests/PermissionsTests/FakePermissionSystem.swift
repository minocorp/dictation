import Core
import Foundation
@testable import Permissions
import Synchronization

internal final class FakePermissionSystem: PermissionSystem {
    private struct State {
        var microphone = MicrophoneAccess.notDetermined
        var isTrusted = false
        var microphoneRequests = 0
        var prompts = 0
        var opened: [URL] = []
        var urlsThatOpen: Set<URL> = []
    }

    private let state = Mutex(State())

    var microphone: MicrophoneAccess {
        get { state.withLock { $0.microphone } }
        set { state.withLock { $0.microphone = newValue } }
    }

    var isTrusted: Bool {
        get { state.withLock { $0.isTrusted } }
        set { state.withLock { $0.isTrusted = newValue } }
    }

    var urlsThatOpen: Set<URL> {
        get { state.withLock { $0.urlsThatOpen } }
        set { state.withLock { $0.urlsThatOpen = newValue } }
    }

    var microphoneRequests: Int { state.withLock { $0.microphoneRequests } }
    var prompts: Int { state.withLock { $0.prompts } }
    var opened: [URL] { state.withLock { $0.opened } }

    func microphoneAccess() -> MicrophoneAccess { microphone }

    func requestMicrophoneAccess() async {
        state.withLock { $0.microphoneRequests += 1 }
    }

    func isAccessibilityTrusted() -> Bool { isTrusted }

    func promptForAccessibility() {
        state.withLock { $0.prompts += 1 }
    }

    func open(_ url: URL) -> Bool {
        state.withLock { state in
            state.opened.append(url)
            return state.urlsThatOpen.contains(url)
        }
    }
}
