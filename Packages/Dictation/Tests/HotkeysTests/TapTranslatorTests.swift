import ApplicationServices
import Core
@testable import Hotkeys
import Testing

internal struct TapTranslatorTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let name: String
        let input: TapInput
        let expected: TapTranslation?

        var testDescription: String { name }
    }

    private static let rightOptionFlag = CGEventFlags(rawValue: 0x40)
    private static let leftOptionFlag = CGEventFlags(rawValue: 0x20)

    private static func input(
        _ kind: TapInput.Kind,
        keyCode: UInt16 = 0,
        flags: CGEventFlags = [],
        mouseButton: Int = 0,
        isRepeat: Bool = false,
    ) -> TapInput {
        TapInput(
            kind: kind,
            keyCode: keyCode,
            flags: flags,
            mouseButton: mouseButton,
            isRepeat: isRepeat,
        )
    }

    private static func translation(
        _ phase: RawKeyEvent.Phase,
        _ trigger: KeyBinding.Trigger,
        _ modifiers: KeyModifiers,
        isRepeat: Bool = false,
    ) -> TapTranslation {
        TapTranslation(
            event: RawKeyEvent(phase: phase, trigger: trigger, modifiers: modifiers),
            isRepeat: isRepeat,
        )
    }

    static let cases = [
        Case(
            name: "key down with chord flags",
            input: input(.keyDown, keyCode: 9, flags: [.maskControl, .maskCommand]),
            expected: translation(.pressed, .key(code: 9), [.control, .command]),
        ),
        Case(
            name: "key up",
            input: input(.keyUp, keyCode: 9, flags: [.maskCommand]),
            expected: translation(.released, .key(code: 9), [.command]),
        ),
        Case(
            name: "auto-repeat key down",
            input: input(.keyDown, keyCode: 9, flags: [.maskCommand], isRepeat: true),
            expected: translation(.pressed, .key(code: 9), [.command], isRepeat: true),
        ),
        Case(
            name: "arrow key does not report Fn",
            input: input(.keyDown, keyCode: 123, flags: [.maskSecondaryFn]),
            expected: translation(.pressed, .key(code: 123), []),
        ),
        Case(
            name: "letter key keeps Fn",
            input: input(.keyDown, keyCode: 0, flags: [.maskSecondaryFn]),
            expected: translation(.pressed, .key(code: 0), [.function]),
        ),
        Case(
            name: "Fn pressed",
            input: input(.flagsChanged, keyCode: 63, flags: [.maskSecondaryFn]),
            expected: translation(.pressed, .key(code: 63), [.function]),
        ),
        Case(
            name: "Fn released",
            input: input(.flagsChanged, keyCode: 63),
            expected: translation(.released, .key(code: 63), []),
        ),
        Case(
            name: "Right Option pressed",
            input: input(.flagsChanged, keyCode: 61, flags: [.maskAlternate, rightOptionFlag]),
            expected: translation(.pressed, .key(code: 61), [.option]),
        ),
        Case(
            name: "Right Option released while Left Option stays down",
            input: input(.flagsChanged, keyCode: 61, flags: [.maskAlternate, leftOptionFlag]),
            expected: translation(.released, .key(code: 61), [.option]),
        ),
        Case(
            name: "Caps Lock is ignored",
            input: input(.flagsChanged, keyCode: 57, flags: [.maskAlphaShift]),
            expected: nil,
        ),
        Case(
            name: "mouse button down",
            input: input(.mouseDown, flags: [.maskShift], mouseButton: 3),
            expected: translation(.pressed, .mouseButton(3), [.shift]),
        ),
        Case(
            name: "mouse button up",
            input: input(.mouseUp, mouseButton: 3),
            expected: translation(.released, .mouseButton(3), []),
        ),
    ]

    @Test(arguments: cases)
    func translatesInput(testCase: Case) {
        #expect(TapTranslator.translate(testCase.input) == testCase.expected)
    }
}
