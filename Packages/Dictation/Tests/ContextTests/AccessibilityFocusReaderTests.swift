import Clocks
@testable import Context
import Core
import CoreTesting
import Foundation
import Pasteboard
import Testing

internal struct AccessibilityFocusReaderTests {
    private let editor = TargetApp(pid: 42, bundleID: "com.example.editor", name: "Editor")

    @Test
    func snapshotIsNilWithoutAFrontmostApp() async {
        let reader = makeReader(app: nil, focus: .noValue)
        #expect(await reader.snapshot() == nil)
    }

    @Test
    func snapshotDescribesTheFocusedField() async {
        let field = FakeAccessibilityElement.field(role: "AXTextField", text: "Hi", cursor: 2)
        let snapshot = await makeReader(app: editor, focus: .value(field)).snapshot()
        #expect(snapshot?.target == editor)
        #expect(snapshot?.fieldKind == .singleLine)
        #expect(snapshot?.textBefore == "Hi")
    }

    @Test
    func snapshotOfAnUnreadableAppStillNamesTheTarget() async {
        let snapshot = await makeReader(app: editor, focus: .unavailable).snapshot()
        #expect(snapshot?.target == editor)
        #expect(snapshot?.fieldKind == .other)
    }

    @Test
    func selectionIsUnreadableWithoutAFrontmostApp() async {
        let reader = makeReader(app: nil, focus: .noValue)
        #expect(await reader.selection(maxCharacters: 4_000) == .unreadable)
    }

    @Test
    func selectionReadsFromTheFocusedField() async {
        let field = FakeAccessibilityElement.field(role: "AXTextArea", text: "pick me")
            .with(.selectedTextRange, .range(NSRange(location: 0, length: 4)))
            .with(.selectedText, .text("pick"))
        let reader = makeReader(app: editor, focus: .value(field))
        #expect(await reader.selection(maxCharacters: 4_000) == .text("pick"))
    }

    @Test
    func selectionInASecureFieldIsUnreadable() async {
        let field = FakeAccessibilityElement.field(role: "AXSecureTextField", text: "secret")
            .with(.selectedTextRange, .range(NSRange(location: 0, length: 6)))
        let reader = makeReader(app: editor, focus: .value(field))
        #expect(await reader.selection(maxCharacters: 4_000) == .unreadable)
    }

    private func makeReader(
        app: TargetApp?,
        focus: AccessibilityRead<FakeAccessibilityElement>,
    ) -> AccessibilityFocusReader {
        let transaction = ClipboardTransaction(
            pasteboard: FakePasteboard(),
            clock: ImmediateClock<Duration>(),
        )
        return AccessibilityFocusReader(
            apps: FakeFrontmostAppSource(app: app),
            focusedElements: FakeFocusedElementSource(result: focus),
            secureInput: FakeSecureInputSource(),
            selections: SelectionReader(transaction: transaction, shortcuts: FakeShortcutPoster()),
        )
    }
}
