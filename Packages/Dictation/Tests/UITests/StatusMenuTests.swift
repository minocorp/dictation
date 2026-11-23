import Core
import Testing
@testable import UI

internal struct StatusMenuTests {
    @Test
    func emptyMenuDisablesPasteLastAndShowsALabel() {
        let entries = StatusMenu.entries(lastResult: nil, canCheckForUpdates: true)
        #expect(entries.first?.kind == .label)
        #expect(entries.first { $0.kind == .item(.pasteLast) }?.isEnabled == false)
    }

    @Test
    func lastResultCopiesOnClick() {
        let entries = StatusMenu.entries(lastResult: "Hello there", canCheckForUpdates: true)
        #expect(entries.first?.kind == .item(.copyLastResult))
        #expect(entries.first?.title == "Hello there")
        #expect(entries.first { $0.kind == .item(.pasteLast) }?.isEnabled == true)
    }

    @Test
    func longMultilineResultsAreSummarized() {
        let text = String(repeating: "word ", count: 40) + "\nsecond line"
        let title = StatusMenu.summary(of: text)
        #expect(title.count == StatusMenu.lastResultCharacterLimit + 1)
        #expect(!title.contains("\n"))
        #expect(title.hasSuffix("…"))
    }

    @Test
    func menuListsEveryActionInOrder() {
        let entries = StatusMenu.entries(lastResult: "x", canCheckForUpdates: true)
        let actions = entries.compactMap { (entry) -> MenuAction? in
            guard case .item(let action) = entry.kind else { return nil }
            return action
        }
        #expect(
            actions == [
                .copyLastResult, .pasteLast, .showHistory, .showSettings, .showAbout,
                .checkForUpdates, .quit,
            ]
        )
    }

    @Test
    func updateCheckFollowsAvailability() {
        let entries = StatusMenu.entries(lastResult: nil, canCheckForUpdates: false)
        #expect(entries.first { $0.kind == .item(.checkForUpdates) }?.isEnabled == false)
    }
}
