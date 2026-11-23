package protocol ShortcutPosting: Sendable {
    func post(_ shortcut: ClipboardShortcut) async -> Bool
}
