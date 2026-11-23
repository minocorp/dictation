import Clocks
@testable import Context
import Core
import CoreTesting
import Foundation
import Pasteboard
import Testing

internal struct SelectionReaderTests {
    private static let limit = 4_000

    private let original = [PasteboardItem.plain("original")]
    private let pasteboard: FakePasteboard
    private let transaction: ClipboardTransaction

    init() {
        let board = FakePasteboard(items: original)
        pasteboard = board
        transaction = ClipboardTransaction(
            pasteboard: board,
            clock: ImmediateClock<Duration>(),
        )
    }

    @Test
    func emptySelectionRangeMeansNoSelection() async {
        let poster = FakeShortcutPoster()
        let selection = await read(
            .field(role: "AXTextArea", text: "abc", cursor: 1),
            poster: poster,
        )
        #expect(selection == .none)
        #expect(poster.posts == 0)
    }

    @Test
    func readsSelectedTextFromAccessibility() async {
        let element = FakeAccessibilityElement.field(role: "AXTextArea", text: "hello world")
            .with(.selectedTextRange, .range(NSRange(location: 6, length: 5)))
            .with(.selectedText, .text("world"))
        let poster = FakeShortcutPoster()
        #expect(await read(element, poster: poster) == .text("world"))
        #expect(poster.posts == 0)
    }

    @Test
    func readsTheRangeWhenSelectedTextIsMissing() async {
        let element = FakeAccessibilityElement.field(role: "AXTextArea", text: "hello world")
            .with(.selectedTextRange, .range(NSRange(location: 6, length: 5)))
        #expect(await read(element, poster: FakeShortcutPoster()) == .text("world"))
    }

    @Test
    func selectedTextAloneIsEnoughWithoutARange() async {
        var element = FakeAccessibilityElement.field(role: "AXTextArea")
        element.attributes[.selectedText] = .value(.text("picked"))
        #expect(await read(element, poster: FakeShortcutPoster()) == .text("picked"))
    }

    @Test
    func aCapExceedingRangeIsTooLongWithoutCopying() async {
        let element = FakeAccessibilityElement.field(role: "AXTextArea", text: "x")
            .with(.selectedTextRange, .range(NSRange(location: 0, length: 9_000)))
        let poster = FakeShortcutPoster()
        #expect(await read(element, poster: poster) == .tooLong)
        #expect(poster.posts == 0)
    }

    @Test
    func selectedTextOverTheCapIsTooLong() async {
        let long = String(repeating: "a", count: Self.limit + 1)
        let element = FakeAccessibilityElement.field(role: "AXTextArea", text: long)
            .with(.selectedTextRange, .range(NSRange(location: 0, length: long.utf16.count)))
        #expect(await read(element, poster: FakeShortcutPoster()) == .tooLong)
    }

    @Test
    func selectedTextAtTheCapIsKept() async {
        let exact = String(repeating: "a", count: Self.limit)
        let element = FakeAccessibilityElement.field(role: "AXTextArea", text: exact)
            .with(.selectedTextRange, .range(NSRange(location: 0, length: exact.utf16.count)))
        #expect(await read(element, poster: FakeShortcutPoster()) == .text(exact))
    }

    @Test
    func copiesWhenAccessibilityHasNoAnswerAndRestoresTheClipboard() async {
        let board = pasteboard
        let poster = FakeShortcutPoster { board.userCopies("copied words") }
        let selection = await read(.noValue, poster: poster)
        #expect(selection == .text("copied words"))
        #expect(pasteboard.currentItems == original)
    }

    @Test
    func aWholeLineCopiedByAnEditorWithNoSelectionMeansNoSelection() async {
        let board = pasteboard
        let poster = FakeShortcutPoster { board.userCopies("let value = 1\n") }
        #expect(await read(.noValue, poster: poster) == .none)
        #expect(pasteboard.currentItems == original)
    }

    @Test
    func aMultiLineCopyIsASelection() async {
        let board = pasteboard
        let poster = FakeShortcutPoster { board.userCopies("one\ntwo\n") }
        #expect(await read(.noValue, poster: poster) == .text("one\ntwo\n"))
    }

    @Test
    func copiedTextOverTheCapIsTooLong() async {
        let board = pasteboard
        let poster = FakeShortcutPoster {
            board.userCopies(String(repeating: "b", count: Self.limit + 1))
        }
        #expect(await read(.noValue, poster: poster) == .tooLong)
    }

    @Test
    func noClipboardChangeAfterCopyMeansNoSelection() async {
        #expect(await read(.noValue, poster: FakeShortcutPoster()) == .none)
    }

    @Test
    func noClipboardChangeWhenAccessibilitySawASelectionIsUnreadable() async {
        let element = FakeAccessibilityElement.field(role: "AXTextArea")
            .with(.selectedTextRange, .range(NSRange(location: 0, length: 4)))
        #expect(await read(element, poster: FakeShortcutPoster()) == .unreadable)
    }

    @Test
    func aShortcutThatCannotBePostedLeavesTheFallback() async {
        #expect(await read(.noValue, poster: FakeShortcutPoster(result: false)) == .none)
    }

    @Test
    func secureFieldsAreUnreadableAndNeverCopied() async {
        let poster = FakeShortcutPoster()
        let selection = await read(.noValue, isSecure: true, poster: poster)
        #expect(selection == .unreadable)
        #expect(poster.posts == 0)
    }

    private func read(
        _ element: FakeAccessibilityElement,
        poster: FakeShortcutPoster,
    ) async -> Selection {
        await reader(poster)
            .read(element: .value(element), isSecure: false, maxCharacters: Self.limit)
    }

    private func read(
        _ read: AccessibilityRead<FakeAccessibilityElement>,
        isSecure: Bool = false,
        poster: FakeShortcutPoster,
    ) async -> Selection {
        let focus = FakeFocusedElementSource(result: read).focusedElement(ofPID: 1)
        return await reader(poster)
            .read(element: focus, isSecure: isSecure, maxCharacters: Self.limit)
    }

    private func reader(_ poster: FakeShortcutPoster) -> SelectionReader {
        SelectionReader(transaction: transaction, shortcuts: poster)
    }
}
