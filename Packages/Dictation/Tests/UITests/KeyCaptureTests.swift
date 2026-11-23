import Core
import Testing
@testable import UI

internal struct KeyCaptureTests {
    struct Case {
        let event: RawKeyEvent
        let kind: KeyRecorderKind
        let expected: KeyCaptureOutcome
    }

    static let cases = [
        Case(
            event: UIFixtures.event(code: 63, modifiers: [.function]),
            kind: .dictateKey,
            expected: .accepted(.fn),
        ),
        Case(
            event: UIFixtures.event(code: 61, modifiers: [.option]),
            kind: .dictateKey,
            expected: .accepted(.rightOption),
        ),
        Case(
            event: UIFixtures.event(.released, code: 63, modifiers: []),
            kind: .dictateKey,
            expected: .ignored,
        ),
        Case(event: UIFixtures.event(code: 53), kind: .dictateKey, expected: .cancelled),
        Case(
            event: UIFixtures.event(code: 9, modifiers: [.control, .command]),
            kind: .shortcut,
            expected: .accepted(.pasteLastDefault),
        ),
        Case(event: UIFixtures.event(code: 9), kind: .shortcut, expected: .ignored),
        Case(
            event: UIFixtures.event(code: 61, modifiers: [.option]),
            kind: .shortcut,
            expected: .ignored,
        ),
        Case(
            event: UIFixtures.event(code: 96),
            kind: .dictateKey,
            expected: .accepted(KeyBinding(trigger: .key(code: 96), modifiers: [])),
        ),
        Case(
            event: RawKeyEvent(phase: .pressed, trigger: .mouseButton(0), modifiers: []),
            kind: .dictateKey,
            expected: .ignored,
        ),
        Case(
            event: RawKeyEvent(phase: .pressed, trigger: .mouseButton(3), modifiers: []),
            kind: .dictateKey,
            expected: .accepted(KeyBinding(trigger: .mouseButton(3), modifiers: [])),
        ),
    ]

    static let modifierCases: [Case] = [
        (63, KeyModifiers.function), (55, .command), (54, .command), (58, .option),
        (61, .option), (59, .control), (62, .control), (56, .shift), (60, .shift),
        (179, .function),
    ]
    .map { code, own in
        Case(
            event: UIFixtures.event(code: UInt16(code), modifiers: own),
            kind: .dictateKey,
            expected: .accepted(KeyBinding(trigger: .key(code: UInt16(code)), modifiers: [])),
        )
    }

    static let chordCases = [
        Case(
            event: UIFixtures.event(code: 55, modifiers: [.control, .command]),
            kind: .dictateKey,
            expected: .accepted(KeyBinding(trigger: .key(code: 55), modifiers: [.control])),
        ),
        Case(
            event: UIFixtures.event(code: 9, modifiers: [.control, .command]),
            kind: .dictateKey,
            expected: .accepted(.pasteLastDefault),
        ),
        Case(
            event: UIFixtures.event(code: 55, modifiers: [.command]),
            kind: .shortcut,
            expected: .ignored,
        ),
        Case(
            event: UIFixtures.event(code: 63, modifiers: [.function]),
            kind: .shortcut,
            expected: .ignored,
        ),
    ]

    @Test(arguments: modifierCases + chordCases)
    func acceptsModifierKeysAndChords(testCase: Case) {
        #expect(KeyCapture.outcome(for: testCase.event, kind: testCase.kind) == testCase.expected)
    }

    @Test(arguments: cases)
    func interpretsRawEvents(testCase: Case) {
        #expect(KeyCapture.outcome(for: testCase.event, kind: testCase.kind) == testCase.expected)
    }
}
