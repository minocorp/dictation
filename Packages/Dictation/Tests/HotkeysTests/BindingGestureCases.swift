import Core

internal enum BindingGestureCases {
    static let all: [GestureCase] =
        editCases + pasteLastCases + globeCases + customBindingCases

    private static let editCases: [GestureCase] = [
        GestureCase(
            "dictate key with control begins an edit",
            steps: [
                .at(0, .fnDownWithControl, [.editBegan]),
                .at(900, .fnUpWithControl, [.released]),
            ],
        ),
        GestureCase(
            "edit release after control was lifted first",
            steps: [.at(0, .fnDownWithControl, [.editBegan]), .at(900, .fnUp, [.released])],
        ),
        GestureCase(
            "short edit press is not a tap so no hands-free follows",
            steps: [
                .at(0, .fnDownWithControl, [.editBegan]),
                .at(100, .fnUpWithControl, [.released]),
                .at(200, .fnDown, [.pressBegan]),
            ],
        ),
        GestureCase(
            "dictate key with shift is not a gesture",
            steps: [.at(0, .fnDownWithShift, []), .at(100, .fnUp, [])],
        ),
        GestureCase(
            "dictate key with control and shift is not a gesture",
            steps: [.at(0, .fnDownWithControlShift, [])],
        ),
    ]

    private static let pasteLastCases: [GestureCase] = [
        GestureCase(
            "paste last chord emits once and repeats are ignored",
            steps: [
                .at(0, .pasteDown, [.pasteLast]),
                .at(50, .pasteDown, []),
                .at(100, .pasteUp, []),
                .at(500, .pasteDown, [.pasteLast]),
            ],
        ),
        GestureCase(
            "paste last release resets even when control was lifted first",
            steps: [
                .at(0, .pasteDown, [.pasteLast]),
                .at(100, .pasteUp, []),
                .at(200, .pasteDown, [.pasteLast]),
            ],
        ),
        GestureCase(
            "paste last needs the exact modifiers",
            steps: [
                .at(0, .pasteDownWithCommandOnly, []),
                .at(10, .pasteDownWithShift, []),
            ],
        ),
        GestureCase(
            "paste last while holding the dictate key leaves the hold alone",
            steps: [
                .at(0, .fnDown, [.pressBegan]),
                .at(100, .pasteDown, [.pasteLast]),
                .at(200, .pasteUp, []),
                .at(800, .fnUp, [.released]),
            ],
        ),
    ]

    private static let globeCases: [GestureCase] = [
        GestureCase(
            "globe key events never disturb an Fn hold",
            steps: [
                .at(0, .fnDown, [.pressBegan]),
                .at(10, .globeDown, []),
                .at(20, .globeUp, []),
                .at(800, .fnUp, [.released]),
            ],
        ),
        GestureCase(
            "globe key alone does nothing for an Fn binding",
            steps: [.at(0, .globeDown, []), .at(100, .globeUp, [])],
        ),
        GestureCase(
            "globe key does not break a double tap",
            steps: [
                .at(0, .fnDown, [.pressBegan]),
                .at(100, .fnUp, [.released]),
                .at(150, .globeDown, []),
                .at(160, .globeUp, []),
                .at(300, .fnDown, [.handsFreeBegan]),
            ],
        ),
        GestureCase(
            "globe key is ignored for a Right Option binding",
            dictateKey: .rightOption,
            steps: [
                .at(0, .rightOptionDown, [.pressBegan]),
                .at(10, .globeDown, []),
                .at(800, .rightOptionUp, [.released]),
            ],
        ),
    ]

    private static let customBindingCases: [GestureCase] = [
        GestureCase(
            "Right Option hold",
            dictateKey: .rightOption,
            steps: [
                .at(0, .rightOptionDown, [.pressBegan]),
                .at(700, .rightOptionUp, [.released]),
            ],
        ),
        GestureCase(
            "Right Option with control begins an edit",
            dictateKey: .rightOption,
            steps: [
                .at(
                    0,
                    RawKeyEvent(
                        phase: .pressed,
                        trigger: .key(code: 61),
                        modifiers: [.option, .control],
                    ),
                    [.editBegan],
                )
            ],
        ),
        GestureCase(
            "mouse button hold",
            dictateKey: KeyBinding(trigger: .mouseButton(3), modifiers: []),
            steps: [.at(0, .mouseDown, [.pressBegan]), .at(700, .mouseUp, [.released])],
        ),
        GestureCase(
            "mouse button double tap",
            dictateKey: KeyBinding(trigger: .mouseButton(3), modifiers: []),
            steps: [
                .at(0, .mouseDown, [.pressBegan]),
                .at(100, .mouseUp, [.released]),
                .at(300, .mouseDown, [.handsFreeBegan]),
            ],
        ),
        GestureCase(
            "key binding with a required modifier",
            dictateKey: KeyBinding(trigger: .key(code: 96), modifiers: [.command]),
            steps: [
                .at(0, .functionKeyDownBare, []),
                .at(10, .functionKeyDown, [.pressBegan]),
                .at(700, .functionKeyUp, [.released]),
            ],
        ),
    ]
}
