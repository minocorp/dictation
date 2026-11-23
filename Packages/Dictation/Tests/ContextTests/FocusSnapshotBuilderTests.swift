@testable import Context
import Core
import Foundation
import Testing

internal struct FocusSnapshotBuilderTests {
    private let target = TargetApp(pid: 42, bundleID: "com.example.editor", name: "Editor")

    @Test
    func readsTextBeforeTheCursor() {
        let snapshot = build(.field(role: "AXTextArea", text: "Hello wor", cursor: 9))
        #expect(snapshot.textBefore == "Hello wor")
        #expect(snapshot.fieldKind == .multiLine)
        #expect(snapshot.fieldID == 7)
    }

    @Test
    func capsTextBeforeAtTwoHundredCharacters() {
        let text = String(repeating: "a", count: 500)
        let snapshot = build(.field(role: "AXTextArea", text: text, cursor: 450))
        #expect(snapshot.textBefore == String(repeating: "a", count: 200))
    }

    @Test
    func readsOnlyUpToTheCursor() {
        let snapshot = build(.field(role: "AXTextField", text: "before after", cursor: 6))
        #expect(snapshot.textBefore == "before")
    }

    @Test
    func fallsBackToTheValueWhenRangeQueriesAreUnsupported() {
        var element = FakeAccessibilityElement.field(
            role: "AXTextField",
            text: "Hello world",
            cursor: 5,
        )
        element.supportsRangeQuery = false
        #expect(build(element).textBefore == "Hello")
    }

    @Test
    func textBeforeIsEmptyAtTheStartOfTheField() {
        #expect(build(.field(role: "AXTextField", text: "abc", cursor: 0)).textBefore == "")
    }

    @Test
    func textBeforeIsUnknownWhenTheSelectionCannotBeRead() {
        var element = FakeAccessibilityElement.field(role: "AXTextField", text: "abc")
        element.attributes[.selectedTextRange] = .unavailable
        #expect(build(element).textBefore == nil)
    }

    @Test
    func dropsAnOrphanedSurrogateAtTheStartOfTheSlice() {
        let text = "😀" + String(repeating: "b", count: 199)
        let snapshot = build(.field(role: "AXTextArea", text: text))
        #expect(snapshot.textBefore == String(repeating: "b", count: 199))
    }

    @Test(
        arguments: [
            ("AXSecureTextField", nil),
            ("AXTextField", "AXSecureTextField"),
        ] as [(String, String?)]
    )
    func secureFieldsExposeNoText(role: String, subrole: String?) {
        let snapshot = build(.field(role: role, subrole: subrole, text: "hunter2"))
        #expect(snapshot.isSecure)
        #expect(snapshot.textBefore == nil)
        #expect(!snapshot.isComposing)
    }

    @Test
    func reportsComposingWhenMarkedTextExists() {
        let element = FakeAccessibilityElement.field(role: "AXTextField", text: "한")
            .with(.markedTextRange, .range(NSRange(location: 0, length: 1)))
        #expect(build(element).isComposing)
    }

    @Test
    func reportsNotComposingForAnEmptyMarkedRange() {
        let element = FakeAccessibilityElement.field(role: "AXTextField", text: "한")
            .with(.markedTextRange, .range(NSRange(location: 0, length: 0)))
        #expect(!build(element).isComposing)
    }

    @Test(arguments: [AccessibilityRead<FakeAccessibilityElement>.noValue, .unavailable])
    func unknownFocusIsTreatedAsUnknownNotAsNoField(
        read: AccessibilityRead<FakeAccessibilityElement>
    ) {
        let snapshot = build(read: read, secureInput: false)
        #expect(snapshot.fieldKind == .other)
        #expect(snapshot.fieldID == nil)
        #expect(!snapshot.isSecure)
        #expect(snapshot.textBefore == nil)
    }

    @Test
    func unknownFocusWithSecureInputActiveIsTreatedAsSecure() {
        #expect(build(read: .noValue, secureInput: true).isSecure)
    }

    @Test
    func aButtonIsNotATextField() {
        #expect(build(.field(role: "AXButton")).fieldKind == .noField)
    }

    @Test
    func aTerminalWithSecureInputOnIsSecureEvenWhenItsTextIsReadable() {
        let terminal = TargetApp(pid: 9, bundleID: "com.apple.Terminal", name: "Terminal")
        let element = FakeAccessibilityElement.field(role: "AXTextArea", text: "Password:")
            .with(.isEditable, .flag(true))
        let snapshot = FocusSnapshotBuilder.build(
            target: terminal,
            focus: FakeFocusedElementSource(result: .value(element)).focusedElement(ofPID: 9),
            isSecureInputActive: true,
        )
        #expect(snapshot.isSecure)
        #expect(snapshot.textBefore == nil)
    }

    @Test
    func anEditableFieldStaysUsableWhenAnotherAppLeftSecureInputOn() {
        let element = FakeAccessibilityElement.field(role: "AXTextArea", text: "Hello")
            .with(.isEditable, .flag(true))
        let snapshot = FocusSnapshotBuilder.build(
            target: target,
            focus: FakeFocusedElementSource(result: .value(element)).focusedElement(ofPID: 42),
            isSecureInputActive: true,
        )
        #expect(!snapshot.isSecure)
        #expect(snapshot.textBefore == "Hello")
    }

    private func build(_ element: FakeAccessibilityElement) -> FocusSnapshot {
        build(read: .value(element), secureInput: false)
    }

    private func build(
        read: AccessibilityRead<FakeAccessibilityElement>,
        secureInput: Bool,
    ) -> FocusSnapshot {
        let focus = FakeFocusedElementSource(result: read)
            .focusedElement(ofPID: target.pid)
        return FocusSnapshotBuilder.build(
            target: target,
            focus: focus,
            isSecureInputActive: secureInput,
        )
    }
}
