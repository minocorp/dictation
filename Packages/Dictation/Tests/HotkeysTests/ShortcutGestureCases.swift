import Core

internal enum ShortcutGestureCases {
    private static let rightCommand = KeyBinding(trigger: .key(code: 54), modifiers: [])

    static let all: [GestureCase] = [
        GestureCase(
            "key pressed while the modifier is held abandons the hold",
            dictateKey: rightCommand,
            steps: [
                .at(0, .rightCommandDown, [.pressBegan]),
                .at(50, .copyDownWithCommand, [.abandon]),
                .at(80, .copyUp, []),
                .at(400, .rightCommandUp, []),
                .at(500, .rightCommandDown, [.pressBegan]),
            ],
        ),
        GestureCase(
            "second shortcut key after an abandon changes nothing",
            dictateKey: rightCommand,
            steps: [
                .at(0, .rightCommandDown, [.pressBegan]),
                .at(50, .copyDownWithCommand, [.abandon]),
                .at(100, .copyDownWithCommand, []),
            ],
        ),
        GestureCase(
            "shortcut key during the second press of a double tap abandons",
            dictateKey: rightCommand,
            steps: [
                .at(0, .rightCommandDown, [.pressBegan]),
                .at(100, .rightCommandUp, [.released]),
                .at(200, .rightCommandDown, [.handsFreeBegan]),
                .at(250, .copyDownWithCommand, [.abandon]),
                .at(300, .rightCommandUp, []),
            ],
        ),
        GestureCase(
            "shortcut key while idle does nothing",
            dictateKey: rightCommand,
            steps: [.at(0, .copyDownWithCommand, [])],
        ),
        GestureCase(
            "shortcut key does not touch hands-free",
            dictateKey: rightCommand,
            steps: [
                .at(0, .rightCommandDown, [.pressBegan]),
                .at(100, .rightCommandUp, [.released]),
                .at(200, .rightCommandDown, [.handsFreeBegan]),
                .at(300, .rightCommandUp, []),
                .at(1_000, .copyDownWithCommand, []),
            ],
        ),
        GestureCase(
            "paste last chord while the modifier is held abandons and pastes",
            dictateKey: KeyBinding(trigger: .key(code: 55), modifiers: []),
            steps: [
                .at(
                    0,
                    RawKeyEvent(phase: .pressed, trigger: .key(code: 55), modifiers: [.command]),
                    [.pressBegan],
                ),
                .at(50, .pasteDown, [.abandon, .pasteLast]),
            ],
        ),
        GestureCase(
            "globe key does not abandon an fn hold",
            steps: [.at(0, .fnDown, [.pressBegan]), .at(10, .globeDown, [])],
        ),
        GestureCase(
            "other key abandons an fn hold",
            steps: [
                .at(0, .fnDown, [.pressBegan]),
                .at(
                    50,
                    RawKeyEvent(phase: .pressed, trigger: .key(code: 0), modifiers: [.function]),
                    [.abandon],
                ),
            ],
        ),
    ]
}
