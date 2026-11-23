import Clocks
import Core
import CoreTesting
@testable import Insertion
import Pasteboard
import Testing

internal struct PasteTextInserterEvidenceTests {
    private static let target = FakeEditor.target

    private let original = [PasteboardItem.plain("original")]
    private let editor: FakeEditor
    private let clipboard = FakeClipboardWriter()
    private let inserter: PasteTextInserter

    init() {
        let board = FakePasteboard(items: [PasteboardItem.plain("original")])
        let fake = FakeEditor(pasteboard: board)
        let clock = ImmediateClock<Duration>()
        let transaction = ClipboardTransaction(pasteboard: board, clock: clock)
        let writer = clipboard
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

    @Test(arguments: [FieldKind.multiLine, .webContent, .other])
    func reportsPasteWhenAReadableFieldNeverUpdatesItsText(kind: FieldKind) async {
        editor.configure {
            $0.fieldKind = kind
            $0.readsStayStale = true
        }
        #expect(await insert("Hello") == .inserted(.pasteShortcut))
        #expect(editor.events == ["shortcut"])
        #expect(editor.pasted == ["Hello"])
        #expect(clipboard.copied.isEmpty)
    }

    @Test
    func neverPastesTwiceIntoAFieldThatCannotProveTheFirstPaste() async {
        editor.configure {
            $0.fieldKind = .multiLine
            $0.readsStayStale = true
            $0.inputMethodActive = false
        }
        _ = await insert("Hello")
        #expect(editor.pasted == ["Hello"])
    }

    @Test
    func aPasteThatLandsLateInASingleLineFieldIsNotRepeated() async {
        editor.configure {
            $0.fieldKind = .singleLine
            $0.shortcutLandsAfterReads = 12
        }
        #expect(await insert("Hello") == .inserted(.pasteShortcut))
        #expect(editor.events == ["shortcut"])
        #expect(editor.pasted == ["Hello"])
    }

    @Test
    func copiesWhenFocusLeavesTheTargetAfterThePaste() async {
        editor.configure { $0.focusPIDAfterPaste = 99 }
        #expect(await insert("Hello") == .copied(.allMethodsFailed))
        #expect(editor.events == ["shortcut"])
        #expect(clipboard.copied == ["Hello"])
    }

    @Test
    func leavesOnlyTheCopiedTextOnTheClipboardWhenThePasteFailsAfterwards() async {
        let board = FakePasteboard(items: original)
        let fake = FakeEditor(pasteboard: board)
        let clock = ImmediateClock<Duration>()
        let transaction = ClipboardTransaction(pasteboard: board, clock: clock)
        let realInserter = PasteTextInserter(
            frontmost: fake,
            modifiers: fake,
            clipboard: PasteboardClipboardWriter(transaction: transaction),
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
        fake.configure {
            $0.fieldKind = .singleLine
            $0.shortcutWorks = false
            $0.menuWorks = false
            $0.typingWorks = false
        }
        let outcome = await realInserter.insert(
            "Hello",
            into: Self.target,
            focus: fake.snapshotFocus(),
        )
        await transaction.settle()
        #expect(outcome == .copied(.allMethodsFailed))
        #expect(board.plainText == "Hello")
    }

    private func insert(_ text: String) async -> InsertOutcome {
        await inserter.insert(text, into: Self.target, focus: editor.snapshotFocus())
    }
}
