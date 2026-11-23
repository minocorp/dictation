import Core

internal enum EscapeGestureCases {
    static let all: [GestureCase] = [
        GestureCase(
            "escape during hold cancels and the later release is silent",
            steps: [
                .at(0, .fnDown, [.pressBegan]),
                .at(300, .escapeDown, [.cancel]),
                .at(350, .escapeUp, []),
                .at(800, .fnUp, []),
            ],
        ),
        GestureCase(
            "escape in hands-free cancels and the next press starts anew",
            steps: [
                .at(0, .fnDown, [.pressBegan]),
                .at(100, .fnUp, [.released]),
                .at(200, .fnDown, [.handsFreeBegan]),
                .at(300, .fnUp, []),
                .at(4_000, .escapeDown, [.cancel]),
                .at(5_000, .fnDown, [.pressBegan]),
            ],
        ),
        GestureCase(
            "escape while idle does nothing",
            steps: [.at(0, .escapeDown, []), .at(10, .escapeUp, [])],
        ),
        GestureCase(
            "escape inside the double-tap window cancels",
            steps: [
                .at(0, .fnDown, [.pressBegan]),
                .at(100, .fnUp, [.released]),
                .at(300, .escapeDown, [.cancel]),
                .at(350, .fnDown, [.pressBegan]),
            ],
        ),
        GestureCase(
            "escape after the double-tap window does nothing",
            steps: [
                .at(0, .fnDown, [.pressBegan]),
                .at(100, .fnUp, [.released]),
                .at(700, .escapeDown, []),
            ],
        ),
        GestureCase(
            "escape after release while processing does nothing",
            steps: [
                .at(0, .fnDown, [.pressBegan]),
                .at(800, .fnUp, [.released]),
                .at(900, .escapeDown, []),
            ],
        ),
        GestureCase(
            "escape while the Fn dictate key is held cancels",
            steps: [
                .at(0, .fnDown, [.pressBegan]),
                .at(300, .escapeDownWithFunction, [.cancel]),
                .at(800, .fnUp, []),
            ],
        ),
        GestureCase(
            "escape while a modifier dictate key is held cancels instead of abandoning",
            dictateKey: KeyBinding.rightOption,
            steps: [
                .at(0, .rightOptionDown, [.pressBegan]),
                .at(300, .escapeDownWithOption, [.cancel]),
                .at(800, .rightOptionUp, []),
            ],
        ),
        GestureCase(
            "escape during an edit hold cancels",
            steps: [
                .at(0, .fnDownWithControl, [.editBegan]),
                .at(300, .escapeDownWithFunctionControl, [.cancel]),
                .at(800, .fnUpWithControl, []),
            ],
        ),
        GestureCase(
            "escape with a modifier does nothing",
            steps: [.at(0, .fnDown, [.pressBegan]), .at(100, .escapeDownWithCommand, [])],
        ),
    ]
}
