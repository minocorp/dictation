import Core

internal enum HoldGestureCases {
    static let all: [GestureCase] = [
        GestureCase(
            "hold releases after speech",
            steps: [.at(0, .fnDown, [.pressBegan]), .at(800, .fnUp, [.released])],
        ),
        GestureCase(
            "quick tap emits pressed and released",
            steps: [.at(0, .fnDown, [.pressBegan]), .at(100, .fnUp, [.released])],
        ),
        GestureCase(
            "hold of 299 ms is a tap so a second press inside the window starts hands-free",
            steps: [
                .at(0, .fnDown, [.pressBegan]),
                .at(299, .fnUp, [.released]),
                .at(600, .fnDown, [.handsFreeBegan]),
            ],
        ),
        GestureCase(
            "hold of 300 ms is not a tap so the next press is a new dictation",
            steps: [
                .at(0, .fnDown, [.pressBegan]),
                .at(300, .fnUp, [.released]),
                .at(400, .fnDown, [.pressBegan]),
            ],
        ),
        GestureCase(
            "second press 399 ms after release starts hands-free",
            steps: [
                .at(0, .fnDown, [.pressBegan]),
                .at(100, .fnUp, [.released]),
                .at(499, .fnDown, [.handsFreeBegan]),
            ],
        ),
        GestureCase(
            "second press exactly 400 ms after release starts hands-free",
            steps: [
                .at(0, .fnDown, [.pressBegan]),
                .at(100, .fnUp, [.released]),
                .at(500, .fnDown, [.handsFreeBegan]),
            ],
        ),
        GestureCase(
            "second press 401 ms after release is a new dictation",
            steps: [
                .at(0, .fnDown, [.pressBegan]),
                .at(100, .fnUp, [.released]),
                .at(501, .fnDown, [.pressBegan]),
            ],
        ),
        GestureCase(
            "hands-free ends on the next press and the cycle restarts",
            steps: [
                .at(0, .fnDown, [.pressBegan]),
                .at(100, .fnUp, [.released]),
                .at(300, .fnDown, [.handsFreeBegan]),
                .at(400, .fnUp, []),
                .at(5_000, .fnDown, [.handsFreeEnded]),
                .at(5_100, .fnUp, []),
                .at(6_000, .fnDown, [.pressBegan]),
            ],
        ),
        GestureCase(
            "long second press of a double tap still lands in hands-free",
            steps: [
                .at(0, .fnDown, [.pressBegan]),
                .at(100, .fnUp, [.released]),
                .at(300, .fnDown, [.handsFreeBegan]),
                .at(2_300, .fnUp, []),
                .at(2_400, .fnDown, [.handsFreeEnded]),
            ],
        ),
        GestureCase(
            "repeated presses while held are ignored",
            steps: [
                .at(0, .fnDown, [.pressBegan]),
                .at(50, .fnDown, []),
                .at(100, .fnDown, []),
                .at(800, .fnUp, [.released]),
            ],
        ),
        GestureCase(
            "repeated presses while ending hands-free are ignored",
            steps: [
                .at(0, .fnDown, [.pressBegan]),
                .at(100, .fnUp, [.released]),
                .at(200, .fnDown, [.handsFreeBegan]),
                .at(250, .fnDown, []),
                .at(300, .fnUp, []),
                .at(900, .fnDown, [.handsFreeEnded]),
                .at(950, .fnDown, []),
                .at(1_000, .fnUp, []),
            ],
        ),
        GestureCase("release without press does nothing", steps: [.at(0, .fnUp, [])]),
        GestureCase(
            "unrelated key does nothing",
            steps: [.at(0, .letterDown, []), .at(10, .fnDown, [.pressBegan])],
        ),
    ]
}
