import Core
@testable import Hotkeys
import Testing

internal struct TapPolicyTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let name: String
        let event: RawKeyEvent
        let swallowsEscape: Bool
        let expected: Bool

        var testDescription: String { name }
    }

    static let cases = [
        Case(name: "dictate key", event: .fnDown, swallowsEscape: false, expected: true),
        Case(name: "edit chord", event: .fnDownWithControl, swallowsEscape: false, expected: true),
        Case(
            name: "dictate key with shift",
            event: .fnDownWithShift,
            swallowsEscape: false,
            expected: false,
        ),
        Case(name: "paste last chord", event: .pasteDown, swallowsEscape: false, expected: true),
        Case(
            name: "paste key without control",
            event: .pasteDownWithCommandOnly,
            swallowsEscape: false,
            expected: false,
        ),
        Case(
            name: "escape while idle",
            event: .escapeDown,
            swallowsEscape: false,
            expected: false,
        ),
        Case(name: "escape while live", event: .escapeDown, swallowsEscape: true, expected: true),
        Case(
            name: "escape with command while live",
            event: .escapeDownWithCommand,
            swallowsEscape: true,
            expected: false,
        ),
        Case(
            name: "escape with the dictate modifier held while live",
            event: .escapeDownWithFunction,
            swallowsEscape: true,
            expected: true,
        ),
        Case(name: "ordinary key", event: .letterDown, swallowsEscape: true, expected: false),
        Case(name: "globe key", event: .globeDown, swallowsEscape: true, expected: false),
    ]

    @Test(arguments: cases)
    func pressSwallowDecision(testCase: Case) {
        let policy = TapPolicy(
            dictateKey: .fn,
            pasteLast: .pasteLastDefault,
            swallowsEscape: testCase.swallowsEscape,
        )
        #expect(policy.shouldSwallowPress(of: testCase.event) == testCase.expected)
    }

    @Test
    func mouseBindingIsSwallowed() {
        let policy = TapPolicy(
            dictateKey: KeyBinding(trigger: .mouseButton(3), modifiers: []),
            pasteLast: .pasteLastDefault,
            swallowsEscape: false,
        )
        #expect(policy.shouldSwallowPress(of: .mouseDown))
    }

    @Test
    func relevantTriggersAreDictatePasteLastAndEscape() {
        let policy = TapPolicy(
            dictateKey: .fn,
            pasteLast: .pasteLastDefault,
            swallowsEscape: false,
        )
        #expect(policy.isRelevant(.fnDown))
        #expect(policy.isRelevant(.pasteDown))
        #expect(policy.isRelevant(.escapeDown))
        #expect(!policy.isRelevant(.letterDown))
    }

    @Test
    func keysPressedWhileTheDictateModifierIsHeldAreRelevant() {
        let policy = TapPolicy(
            dictateKey: KeyBinding(trigger: .key(code: 54), modifiers: []),
            pasteLast: .pasteLastDefault,
            swallowsEscape: false,
        )
        #expect(policy.isRelevant(.copyDownWithCommand))
        #expect(!policy.isRelevant(.copyUp))
        #expect(!policy.isRelevant(.letterDown))
    }

    @Test
    func globeKeyIsNotAShortcutWhileFnIsHeld() {
        let policy = TapPolicy(
            dictateKey: .fn,
            pasteLast: .pasteLastDefault,
            swallowsEscape: false,
        )
        #expect(!policy.isRelevant(.globeDown))
    }

    @Test(arguments: [
        (UInt16(54), false), (55, false), (56, false), (58, false), (59, false), (63, true),
    ])
    func onlyFnAmongModifierKeysIsSwallowedAsDictateKey(code: UInt16, expected: Bool) {
        let policy = TapPolicy(
            dictateKey: KeyBinding(trigger: .key(code: code), modifiers: []),
            pasteLast: .pasteLastDefault,
            swallowsEscape: false,
        )
        let event = RawKeyEvent(phase: .pressed, trigger: .key(code: code), modifiers: [])
        #expect(policy.shouldSwallowPress(of: event) == expected)
    }
}
