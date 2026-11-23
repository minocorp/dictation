import Clocks
import Core
import CoreTesting
@testable import Insertion
import Pasteboard
import Testing

internal struct PasteTextInserterJoiningTests {
    private static let target = FakeEditor.target

    private let editor: FakeEditor
    private let inserter: PasteTextInserter
    private let instant = ManualInstant()

    init() {
        let board = FakePasteboard()
        let fake = FakeEditor(pasteboard: board)
        let clock = ImmediateClock<Duration>()
        let instant = instant
        editor = fake
        inserter = PasteTextInserter(
            frontmost: fake,
            modifiers: fake,
            clipboard: FakeClipboardWriter(),
            chain: InsertionChain(
                transaction: ClipboardTransaction(pasteboard: board, clock: clock),
                shortcuts: fake,
                focusReader: fake,
                menu: fake,
                typer: fake,
                inputMethod: fake,
                clock: clock,
            ),
            now: { instant.value },
        )
    }

    @Test
    func joinsFromTheLiveTextBeforeTheCursor() async {
        editor.configure { $0.textBefore = "Hello." }
        _ = await insert("how are you")
        #expect(editor.pasted == [" How are you"])
    }

    @Test
    func insertsAsIsAtTheStartOfAnEmptyField() async {
        _ = await insert("hello")
        #expect(editor.pasted == ["hello"])
    }

    @Test
    func joinsFromThePreviousInsertWhenTheFieldHasNoReadableText() async {
        editor.configure { $0.textBefore = nil }
        _ = await insert("Hello there.")
        _ = await insert("how are you")
        #expect(editor.pasted == ["Hello there.", " How are you"])
    }

    @Test
    func joinsKoreanSentencesFromThePreviousInsertWithASpace() async {
        editor.configure { $0.textBefore = nil }
        _ = await insert("잘돼.")
        _ = await insert("리액트 이거 어떻게 쓰는지 알아?")
        #expect(editor.pasted == ["잘돼.", " 리액트 이거 어떻게 쓰는지 알아?"])
    }

    @Test
    func joinsFromThePreviousInsertWhenOnlyOneSideKnowsTheField() async {
        editor.configure {
            $0.textBefore = nil
            $0.fieldID = nil
        }
        _ = await insert("Hello there.")
        editor.configure { $0.fieldID = 5 }
        _ = await insert("how are you")
        editor.configure { $0.fieldID = nil }
        _ = await insert("fine.")
        #expect(editor.pasted == ["Hello there.", " How are you", " fine."])
    }

    @Test
    func forgetsThePreviousInsertAfterThirtySeconds() async {
        editor.configure { $0.textBefore = nil }
        _ = await insert("Hello there.")
        instant.advance(by: .seconds(31))
        _ = await insert("how are you")
        #expect(editor.pasted == ["Hello there.", "how are you"])
    }

    @Test
    func doesNotJoinAcrossDifferentFields() async {
        editor.configure { $0.textBefore = nil }
        _ = await insert("Hello there.")
        editor.configure { $0.fieldID = 6 }
        _ = await insert("how are you")
        #expect(editor.pasted == ["Hello there.", "how are you"])
    }

    @Test
    func doesNotJoinAcrossDifferentApps() async {
        editor.configure { $0.textBefore = nil }
        _ = await insert("Hello there.")
        let other = TargetApp(pid: 43, bundleID: "com.example.other", name: "Other")
        editor.configure { $0.frontmostPID = 43 }
        let outcome = await inserter.insert(
            "how are you",
            into: other,
            focus: editor.snapshotFocus(),
        )
        #expect(outcome != .refused(.secureField))
        #expect(editor.pasted.first == "Hello there.")
    }

    @Test
    func readableTextWinsOverThePreviousInsert() async {
        editor.configure { $0.textBefore = nil }
        _ = await insert("Hello there.")
        editor.configure { $0.textBefore = "Different text" }
        _ = await insert("foo")
        #expect(editor.pasted == ["Hello there.", " foo"])
    }

    @Test
    func fallsBackToTheKeyDownTextBeforeWhenTheLiveReadHasNone() async {
        editor.configure { $0.textBefore = "Hello." }
        let focus = editor.snapshotFocus()
        editor.configure { $0.textBefore = nil }
        _ = await inserter.insert("how are you", into: Self.target, focus: focus)
        #expect(editor.pasted == [" How are you"])
    }

    private func insert(_ text: String) async -> InsertOutcome {
        await inserter.insert(text, into: Self.target, focus: editor.snapshotFocus())
    }
}
