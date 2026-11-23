import Carbon

internal struct SystemInputMethodProbe: InputMethodProbe {
    func isInputMethodActive() async -> Bool {
        await MainActor.run { Self.currentSourceIsInputMethod() }
    }

    @MainActor
    private static func currentSourceIsInputMethod() -> Bool {
        guard
            let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
            let raw = TISGetInputSourceProperty(source, kTISPropertyInputSourceType)
        else { return false }
        let type = Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue()
        return (type as String) != (kTISTypeKeyboardLayout as String)
    }
}
