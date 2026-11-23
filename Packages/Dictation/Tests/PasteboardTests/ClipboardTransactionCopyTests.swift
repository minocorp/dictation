import Clocks
import CoreTesting
import Foundation
@testable import Pasteboard
import Testing

internal struct ClipboardTransactionCopyTests {
    private let original = [PasteboardItem.plain("original")]

    private let pasteboard: FakePasteboard
    private let transaction: ClipboardTransaction

    init() {
        let board = FakePasteboard(items: original)
        pasteboard = board
        transaction = ClipboardTransaction(pasteboard: board, clock: ImmediateClock<Duration>())
    }

    @Test
    func returnsTheCopiedTextAndRestoresTheClipboard() async {
        let board = pasteboard
        let text = await transaction.copyingSelection {
            board.userCopies("selected words")
            return true
        }
        #expect(text == "selected words")
        #expect(pasteboard.currentItems == original)
    }

    @Test
    func returnsNilWhenTheClipboardNeverChanges() async {
        let text = await transaction.copyingSelection { true }
        #expect(text == nil)
        #expect(pasteboard.currentItems == original)
    }

    @Test
    func returnsNilWithoutWaitingWhenTheShortcutCannotBePosted() async {
        let text = await transaction.copyingSelection { false }
        #expect(text == nil)
        #expect(pasteboard.changeCount == 0)
    }

    @Test
    func restoresTheBaselineOfAPendingPasteAfterAnEmptyCopy() async {
        await transaction.pasting("dictated") {}
        let text = await transaction.copyingSelection { true }
        await transaction.settle()
        #expect(text == nil)
        #expect(pasteboard.currentItems == original)
    }

    @Test
    func copiedTextIsReadAsUTF8() async {
        let board = pasteboard
        let text = await transaction.copyingSelection {
            board.userCopies("안녕 hello")
            return true
        }
        #expect(text == "안녕 hello")
    }
}
