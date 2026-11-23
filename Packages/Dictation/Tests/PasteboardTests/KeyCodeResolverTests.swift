@testable import Pasteboard
import Testing

internal struct KeyCodeResolverTests {
    private struct Case: Sendable {
        let name: String
        let layout: FakeKeyLayout?
        let shortcut: ClipboardShortcut
        let keyCode: UInt16
    }

    private static let cases = [
        Case(name: "qwerty paste", layout: .qwerty, shortcut: .paste, keyCode: 9),
        Case(name: "qwerty copy", layout: .qwerty, shortcut: .copy, keyCode: 8),
        Case(name: "dvorak paste", layout: .dvorak, shortcut: .paste, keyCode: 47),
        Case(name: "dvorak copy", layout: .dvorak, shortcut: .copy, keyCode: 34),
        Case(
            name: "dvorak with qwerty command",
            layout: .dvorakQwertyCommand,
            shortcut: .paste,
            keyCode: 9,
        ),
        Case(name: "missing layout", layout: nil, shortcut: .paste, keyCode: 9),
        Case(name: "layout without the letter", layout: .cyrillic, shortcut: .copy, keyCode: 8),
        Case(name: "uppercase result", layout: .shouting, shortcut: .paste, keyCode: 9),
    ]

    @Test(arguments: cases)
    private func resolvesKeyCode(testCase: Case) {
        let keyCode = KeyCodeResolver.keyCode(for: testCase.shortcut, in: testCase.layout)
        #expect(keyCode == testCase.keyCode, "\(testCase.name)")
    }

    @Test
    func prefersTheAnsiKeyWhenTwoKeysProduceTheLetter() {
        let layout = FakeKeyLayout(commandMap: [9: "v", 3: "v"])
        #expect(KeyCodeResolver.keyCode(for: .paste, in: layout) == 9)
    }

    @Test
    func picksTheLowestKeyWhenTheAnsiKeyDoesNotProduceTheLetter() {
        let layout = FakeKeyLayout(commandMap: [60: "v", 50: "v"])
        #expect(KeyCodeResolver.keyCode(for: .paste, in: layout) == 50)
    }
}
