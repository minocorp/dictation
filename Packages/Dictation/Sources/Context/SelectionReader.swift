import Core
import Foundation
import Pasteboard

internal struct SelectionReader: Sendable {
    private enum AccessibilityOutcome {
        case resolved(Selection)
        case unknown
        case existsButUnreadable
    }

    private static let utf16UnitsPerCharacterLimit = 2

    let transaction: ClipboardTransaction
    let shortcuts: any ShortcutPosting

    func read(
        element: AccessibilityRead<any AccessibilityElement>,
        isSecure: Bool,
        maxCharacters: Int,
    ) async -> Selection {
        if isSecure { return .unreadable }
        var existsButUnreadable = false
        if case .value(let element) = element {
            switch Self.accessibilityOutcome(of: element, maxCharacters: maxCharacters) {
            case .resolved(let selection): return selection
            case .existsButUnreadable: existsButUnreadable = true
            case .unknown: break
            }
        }
        return await copiedSelection(
            maxCharacters: maxCharacters,
            fallback: existsButUnreadable ? .unreadable : .none,
        )
    }

    private func copiedSelection(maxCharacters: Int, fallback: Selection) async -> Selection {
        let shortcuts = shortcuts
        let copied = await transaction.copyingSelection { await shortcuts.post(.copy) }
        guard let copied, !copied.isEmpty else { return fallback }
        if fallback == .none, Self.isWholeLineCopy(copied) { return .none }
        return Self.selection(for: copied, maxCharacters: maxCharacters)
    }

    private static func isWholeLineCopy(_ copied: String) -> Bool {
        copied.last?.isNewline == true && !copied.dropLast().contains(where: \.isNewline)
    }

    private static func accessibilityOutcome(
        of element: any AccessibilityElement,
        maxCharacters: Int,
    ) -> AccessibilityOutcome {
        guard case .value(let range) = element.range(.selectedTextRange) else {
            return selectedTextOutcome(of: element, maxCharacters: maxCharacters)
        }
        if range.length == 0 { return .resolved(.none) }
        if range.length > maxCharacters * utf16UnitsPerCharacterLimit {
            return .resolved(.tooLong)
        }
        let text = element.string(.selectedText).value ?? element.text(in: range).value
        guard let text, !text.isEmpty else { return .existsButUnreadable }
        return .resolved(selection(for: text, maxCharacters: maxCharacters))
    }

    private static func selectedTextOutcome(
        of element: any AccessibilityElement,
        maxCharacters: Int,
    ) -> AccessibilityOutcome {
        guard case .value(let text) = element.string(.selectedText) else { return .unknown }
        guard !text.isEmpty else { return .resolved(.none) }
        return .resolved(selection(for: text, maxCharacters: maxCharacters))
    }

    private static func selection(for text: String, maxCharacters: Int) -> Selection {
        text.count > maxCharacters ? .tooLong : .text(text)
    }
}
