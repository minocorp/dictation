package enum KeyCodeResolver {
    package static let keyCodeCount: UInt16 = 128

    package static func keyCode(
        for shortcut: ClipboardShortcut,
        in layout: (any KeyTranslating)?,
    ) -> UInt16 {
        guard let layout else { return shortcut.ansiKeyCode }
        let matching = (0..<keyCodeCount)
            .filter {
                layout.characters(forKeyCode: $0, commandHeld: true).lowercased()
                    == shortcut.character
            }
        if matching.contains(shortcut.ansiKeyCode) { return shortcut.ansiKeyCode }
        return matching.first ?? shortcut.ansiKeyCode
    }
}
