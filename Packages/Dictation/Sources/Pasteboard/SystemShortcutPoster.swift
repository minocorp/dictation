import AppKit

package struct SystemShortcutPoster: ShortcutPosting {
    private struct KeyStep {
        let key: CGKeyCode
        let isDown: Bool
        let flags: CGEventFlags
    }

    private static let commandKeyCode: CGKeyCode = 0x37

    private let layouts: any KeyboardLayoutSource

    package init(layouts: any KeyboardLayoutSource = SystemKeyboardLayoutSource()) {
        self.layouts = layouts
    }

    package func post(_ shortcut: ClipboardShortcut) async -> Bool {
        guard AXIsProcessTrusted() else { return false }
        let keyCode = KeyCodeResolver.keyCode(for: shortcut, in: await layouts.currentLayout())
        return Self.postCommandChord(keyCode: keyCode)
    }

    private static func postCommandChord(keyCode: CGKeyCode) -> Bool {
        guard let source = CGEventSource(stateID: .privateState) else { return false }
        let steps = [
            KeyStep(key: commandKeyCode, isDown: true, flags: .maskCommand),
            KeyStep(key: keyCode, isDown: true, flags: .maskCommand),
            KeyStep(key: keyCode, isDown: false, flags: .maskCommand),
            KeyStep(key: commandKeyCode, isDown: false, flags: []),
        ]
        let events = steps.compactMap { step -> CGEvent? in
            let event = CGEvent(
                keyboardEventSource: source,
                virtualKey: step.key,
                keyDown: step.isDown,
            )
            event?.flags = step.flags
            return event
        }
        guard events.count == steps.count else { return false }
        for event in events {
            event.post(tap: .cghidEventTap)
        }
        return true
    }
}
