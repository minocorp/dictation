import Core
import Testing
@testable import UI

internal struct KeyBindingLabelTests {
    struct Case {
        let binding: KeyBinding
        let contains: String
    }

    static let cases = [
        Case(binding: .fn, contains: "fn"),
        Case(binding: .pasteLastDefault, contains: "⌃⌘V"),
        Case(binding: KeyBinding(trigger: .key(code: 96), modifiers: []), contains: "F5"),
        Case(binding: KeyBinding(trigger: .key(code: 49), modifiers: [.option]), contains: "⌥␣"),
        Case(binding: KeyBinding(trigger: .mouseButton(3), modifiers: []), contains: "4"),
    ]

    @Test(arguments: cases)
    func labelShowsModifiersThenKey(testCase: Case) {
        #expect(testCase.binding.label.contains(testCase.contains))
    }

    @Test
    func rightOptionNamesItsSide() {
        let label = KeyBinding.rightOption.label
        #expect(label.contains("Option"))
        #expect(label.contains(UIString.string(UIString.keyRight)))
    }
}
