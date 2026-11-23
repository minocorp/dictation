import Clocks
import Core
import CoreTesting
@testable import Insertion
import Pasteboard
import Testing

internal struct PasteTextInserterTests {
    private static let target = FakeEditor.target

    private let original = [PasteboardItem.plain("original")]
    private let pasteboard: FakePasteboard
    private let transaction: ClipboardTransaction
    private let editor: FakeEditor
    private let clipboard = FakeClipboardWriter()
    private let inserter: PasteTextInserter

    init() {
        let board = FakePasteboard(items: [PasteboardItem.plain("original")])
        let fake = FakeEditor(pasteboard: board)
        let clock = ImmediateClock<Duration>()
        let transaction = ClipboardTransaction(pasteboard: board, clock: clock)
        let writer = clipboard
        pasteboard = board
        self.transaction = transaction
        editor = fake
        inserter = PasteTextInserter(
            frontmost: fake,
            modifiers: fake,
            clipboard: writer,
            chain: InsertionChain(
                transaction: transaction,
                shortcuts: fake,
                focusReader: fake,
                menu: fake,
                typer: fake,
                inputMethod: fake,
                clock: clock,
            ),
        )
    }

    @Test
    func pastesWithTheShortcutFirstAndRestoresTheClipboard() async {
        let outcome = await insert("Hello")
        await transaction.settle()
        #expect(outcome == .inserted(.pasteShortcut))
        #expect(editor.events == ["shortcut"])
        #expect(editor.pasted == ["Hello"])
        #expect(pasteboard.currentItems == original)
    }

    @Test
    func fallsBackToTheMenuWhenAPlainFieldProvablyIgnoredTheShortcut() async {
        editor.configure {
            $0.fieldKind = .singleLine
            $0.shortcutWorks = false
        }
        #expect(await insert("Hello") == .inserted(.pasteMenu))
        #expect(editor.events == ["shortcut", "menu"])
    }

    @Test
    func fallsBackToTheMenuWhenTheShortcutCannotBePosted() async {
        editor.configure { $0.canPostShortcut = false }
        #expect(await insert("Hello") == .inserted(.pasteMenu))
        #expect(editor.events == ["menu"])
    }

    @Test
    func fallsBackToTypingWhenBothPasteMethodsFail() async {
        editor.configure {
            $0.fieldKind = .singleLine
            $0.shortcutWorks = false
            $0.menuWorks = false
        }
        #expect(await insert("Hello") == .inserted(.typedUnicode))
        #expect(editor.events == ["shortcut", "menu", "type"])
    }

    @Test
    func skipsTheMenuWhenThereIsNoPasteItem() async {
        editor.configure {
            $0.fieldKind = .singleLine
            $0.shortcutWorks = false
            $0.menuAvailable = false
        }
        #expect(await insert("Hello") == .inserted(.typedUnicode))
        #expect(editor.events == ["shortcut", "type"])
    }

    @Test
    func neverTypesWhileAnInputMethodIsActive() async {
        editor.configure {
            $0.fieldKind = .singleLine
            $0.shortcutWorks = false
            $0.menuWorks = false
            $0.inputMethodActive = true
        }
        #expect(await insert("Hello") == .copied(.allMethodsFailed))
        #expect(!editor.events.contains("type"))
        #expect(clipboard.copied == ["Hello"])
    }

    @Test
    func copiesWhenEveryMethodFails() async {
        editor.configure {
            $0.fieldKind = .singleLine
            $0.shortcutWorks = false
            $0.menuWorks = false
            $0.typingWorks = false
        }
        #expect(await insert("Hello") == .copied(.allMethodsFailed))
        #expect(clipboard.copied == ["Hello"])
    }

    @Test
    func assumesTheShortcutWorkedWhenTheFieldCannotBeRead() async {
        editor.configure {
            $0.textBefore = nil
            $0.shortcutWorks = false
        }
        #expect(await insert("Hello") == .inserted(.pasteShortcut))
        #expect(editor.events == ["shortcut"])
        #expect(editor.snapshotCount <= 3)
    }

    @Test
    func copiesWhenAnotherAppIsFrontmost() async {
        editor.configure { $0.frontmostPID = 99 }
        #expect(await insert("Hello") == .copied(.targetLostFocus))
        #expect(clipboard.copied == ["Hello"])
        #expect(editor.events.isEmpty)
    }

    @Test
    func copiesWhenTheTargetChangesWhileWaitingForModifiers() async {
        editor.configure {
            $0.heldReads = 3
            $0.onModifierRead = { $0.frontmostPID = 99 }
        }
        #expect(await insert("Hello") == .copied(.targetLostFocus))
        #expect(clipboard.copied == ["Hello"])
    }

    @Test
    func copiesWhenNoTextFieldHasFocus() async {
        let focus = FocusSnapshot(
            target: Self.target,
            fieldKind: .noField,
            fieldID: nil,
            isSecure: false,
            isComposing: false,
            textBefore: nil,
        )
        #expect(
            await inserter.insert("Hello", into: Self.target, focus: focus) == .copied(.noTextField)
        )
    }

    @Test
    func refusesAPasswordFieldWithoutCopying() async {
        editor.configure { $0.isSecure = true }
        let focus = editor.snapshotFocus()
        let outcome = await inserter.insert("Hello", into: Self.target, focus: focus)
        #expect(outcome == .refused(.secureField))
        #expect(clipboard.copied.isEmpty)
        #expect(editor.events.isEmpty)
    }

    @Test
    func refusesWhenTheFieldTurnsSecureBeforeThePaste() async {
        let focus = editor.snapshotFocus()
        editor.configure { $0.isSecure = true }
        let outcome = await inserter.insert("Hello", into: Self.target, focus: focus)
        #expect(outcome == .refused(.secureField))
        #expect(clipboard.copied.isEmpty)
    }

    @Test
    func copiesWhenModifiersStayHeldPastTheLimit() async {
        editor.configure { $0.heldReads = .max }
        #expect(await insert("Hello") == .copied(.modifiersHeld))
        #expect(clipboard.copied == ["Hello"])
        #expect(editor.events.isEmpty)
    }

    @Test
    func pastesOnceModifiersAreReleasedInTime() async {
        editor.configure { $0.heldReads = 20 }
        #expect(await insert("Hello") == .inserted(.pasteShortcut))
    }

    @Test
    func waitsForComposingTextToCommit() async {
        editor.configure { $0.composingReads = 10 }
        #expect(await insert("Hello") == .inserted(.pasteShortcut))
        #expect(editor.pasted == ["Hello"])
    }

    @Test
    func copiesWhenComposingNeverCommits() async {
        editor.configure { $0.composingReads = .max }
        #expect(await insert("Hello") == .copied(.composingTimeout))
        #expect(editor.events.isEmpty)
        #expect(editor.snapshotCount == 31)
    }

    @Test
    func serializesConcurrentSessions() async {
        let first = Task { await insert("one") }
        let second = Task { await insert("two") }
        _ = await (first.value, second.value)
        #expect(editor.maxRunning == 1)
        #expect(editor.pasted.count == 2)
    }

    private func insert(_ text: String) async -> InsertOutcome {
        await inserter.insert(text, into: Self.target, focus: editor.snapshotFocus())
    }
}
