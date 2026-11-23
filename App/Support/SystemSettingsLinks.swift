import AppKit

@MainActor
internal enum SystemSettingsLinks {
    static func openKeyboard() {
        guard
            let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension")
        else { return }
        NSWorkspace.shared.open(url)
    }
}
