import Core
import CoreTesting
import Foundation
@testable import Insertion
import Pasteboard
import Synchronization

internal final class FakeEditor: Sendable {
    struct State {
        var frontmostPID: Int32
        var textBefore: String?
        var fieldID: Int? = 5
        var isSecure = false
        var fieldKind = FieldKind.multiLine
        var readsStayStale = false
        var shortcutLandsAfterReads: Int?
        var landing: (text: String, atRead: Int)?
        var focusPIDAfterPaste: Int32?
        var livePID: Int32?
        var composingReads = 0
        var heldReads = 0
        var inputMethodActive = false
        var canPostShortcut = true
        var shortcutWorks = true
        var menuAvailable = true
        var menuWorks = true
        var typingWorks = true
        var events: [String] = []
        var pasted: [String] = []
        var snapshotCount = 0
        var running = 0
        var maxRunning = 0
        var onModifierRead: (@Sendable (inout State) -> Void)?
    }

    static let target = TargetApp(pid: 42, bundleID: "com.example.editor", name: "Editor")

    let pasteboard: FakePasteboard
    private let state: Mutex<State>

    var events: [String] { state.withLock { $0.events } }
    var pasted: [String] { state.withLock { $0.pasted } }
    var snapshotCount: Int { state.withLock { $0.snapshotCount } }
    var maxRunning: Int { state.withLock { $0.maxRunning } }
    var textBefore: String? { state.withLock { $0.textBefore } }

    init(pasteboard: FakePasteboard, textBefore: String? = "") {
        self.pasteboard = pasteboard
        state = Mutex(State(frontmostPID: Self.target.pid, textBefore: textBefore))
    }

    func configure(_ change: (inout State) -> Void) {
        state.withLock { change(&$0) }
    }

    func snapshotFocus() -> FocusSnapshot {
        state.withLock { state in
            FocusSnapshot(
                target: Self.target,
                fieldKind: state.fieldKind,
                fieldID: state.fieldID,
                isSecure: state.isSecure,
                isComposing: false,
                textBefore: state.textBefore,
            )
        }
    }

    private func apply(_ text: String) {
        state.withLock { state in
            state.pasted.append(text)
            if let pid = state.focusPIDAfterPaste { state.livePID = pid }
            if let before = state.textBefore, !state.readsStayStale {
                state.textBefore = before + text
            }
        }
    }

    private func clipboardText() -> String {
        pasteboard.plainText ?? ""
    }
}

extension FakeEditor: FocusReader {
    func snapshot() async -> FocusSnapshot? {
        state.withLock { state in
            state.snapshotCount += 1
            if let landing = state.landing, state.snapshotCount >= landing.atRead {
                state.landing = nil
                state.pasted.append(landing.text)
                state.textBefore = (state.textBefore ?? "") + landing.text
            }
            let composing = state.composingReads > 0
            if composing { state.composingReads -= 1 }
            let target = state.livePID.map {
                TargetApp(pid: $0, bundleID: "com.example.other", name: "Other")
            }
            return FocusSnapshot(
                target: target ?? Self.target,
                fieldKind: state.fieldKind,
                fieldID: state.fieldID,
                isSecure: state.isSecure,
                isComposing: composing,
                textBefore: state.textBefore,
            )
        }
    }

    func selection(maxCharacters: Int) async -> Selection { .none }
}

extension FakeEditor: ShortcutPosting {
    func post(_ shortcut: ClipboardShortcut) async -> Bool {
        let accepted = state.withLock { state -> Bool in
            state.running += 1
            state.maxRunning = max(state.maxRunning, state.running)
            if state.canPostShortcut { state.events.append("shortcut") }
            return state.canPostShortcut
        }
        await Task.yield()
        state.withLock { $0.running -= 1 }
        guard accepted, state.withLock({ $0.shortcutWorks }) else { return accepted }
        let text = clipboardText()
        if let delay = state.withLock({ $0.shortcutLandsAfterReads }) {
            state.withLock { $0.landing = (text, $0.snapshotCount + delay) }
        } else {
            apply(text)
        }
        return accepted
    }
}

extension FakeEditor: MenuPaster {
    func pressPaste(pid: Int32) -> Bool {
        let available = state.withLock { state -> Bool in
            if state.menuAvailable { state.events.append("menu") }
            return state.menuAvailable
        }
        if available, state.withLock({ $0.menuWorks }) { apply(clipboardText()) }
        return available
    }
}

extension FakeEditor: UnicodeTyper {
    func type(_ text: String) -> Bool {
        state.withLock { $0.events.append("type") }
        if state.withLock({ $0.typingWorks }) { apply(text) }
        return true
    }
}

extension FakeEditor: InputMethodProbe {
    func isInputMethodActive() async -> Bool {
        state.withLock { $0.inputMethodActive }
    }
}

extension FakeEditor: ModifierState {
    func heldModifiers() -> KeyModifiers {
        state.withLock { state in
            state.onModifierRead?(&state)
            guard state.heldReads > 0 else { return [] }
            state.heldReads -= 1
            return [.command]
        }
    }
}

extension FakeEditor: FrontmostApplication {
    func frontmostPID() -> Int32? {
        state.withLock { $0.frontmostPID }
    }
}
