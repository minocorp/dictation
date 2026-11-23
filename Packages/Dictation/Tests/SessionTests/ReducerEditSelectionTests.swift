import Core
@testable import Session
import Testing

internal struct ReducerEditSelectionTests {
    private static let discardEffects: [Effect] = [
        .cancelWork(Fixture.first),
        .discardCapture(Fixture.first),
    ]
    private static let finishAfterRelease: [Effect] = [
        .stopCapture(Fixture.first),
        .play(.finish),
        .startTimer(.processingDelay, Script.processingDelay),
        .setTapPolicy(Fixture.policy(swallowsEscape: false)),
    ]

    private static let editCases: [ReducerCase] = [
        ReducerCase(
            "edit press starts capturing while the selection is read",
            event: Fixture.gesture(.editBegan),
            effects: [
                .readFocus(Fixture.first),
                Script.startCapture,
                .readSelection(Fixture.first),
                .setTapPolicy(Fixture.policy(swallowsEscape: true)),
            ],
            hud: .editing,
            isLive: true,
        ),
        ReducerCase(
            "selected text keeps the capture as an edit",
            setup: [Fixture.gesture(.editBegan)],
            event: Fixture.input(.selection(.text("hello"))),
            effects: [],
            hud: .editing,
            isLive: true,
        ),
        ReducerCase(
            "empty selection falls back to plain dictation",
            setup: [Fixture.gesture(.editBegan)],
            event: Fixture.input(.selection(.none)),
            effects: [],
            hud: .listening,
            isLive: true,
        ),
        ReducerCase(
            "selection too long discards the capture and shows a problem",
            setup: [Fixture.gesture(.editBegan)],
            event: Fixture.input(.selection(.tooLong)),
            effects: discardEffects + [
                .startTimer(.hudExpiry, .seconds(8)),
                .setTapPolicy(Fixture.policy(swallowsEscape: false)),
            ],
            hud: .problem(.selectionTooLong),
            isLive: false,
        ),
        ReducerCase(
            "unreadable selection discards the capture and shows a problem",
            setup: [Fixture.gesture(.editBegan)],
            event: Fixture.input(.selection(.unreadable)),
            effects: discardEffects + [
                .startTimer(.hudExpiry, .seconds(8)),
                .setTapPolicy(Fixture.policy(swallowsEscape: false)),
            ],
            hud: .problem(.couldNotEdit),
            isLive: false,
        ),
        ReducerCase(
            "release while reading the selection waits for the selection",
            setup: [Fixture.gesture(.editBegan)],
            event: Fixture.gesture(.released),
            effects: [],
            hud: .editing,
            isLive: true,
        ),
        ReducerCase(
            "selected text after an early release finishes the edit",
            setup: [Fixture.gesture(.editBegan), Fixture.gesture(.released)],
            event: Fixture.input(.selection(.text("hello"))),
            effects: finishAfterRelease,
            hud: .hidden,
            isLive: false,
        ),
        ReducerCase(
            "empty selection after an early release finishes a plain dictation",
            setup: [Fixture.gesture(.editBegan), Fixture.gesture(.released)],
            event: Fixture.input(.selection(.none)),
            effects: finishAfterRelease,
            hud: .hidden,
            isLive: false,
        ),
        ReducerCase(
            "refused selection after an early release discards the capture",
            setup: [Fixture.gesture(.editBegan), Fixture.gesture(.released)],
            event: Fixture.input(.selection(.tooLong)),
            effects: discardEffects + [
                .startTimer(.hudExpiry, .seconds(8)),
                .setTapPolicy(Fixture.policy(swallowsEscape: false)),
            ],
            hud: .problem(.selectionTooLong),
            isLive: false,
        ),
        ReducerCase(
            "escape while reading the selection discards the capture",
            setup: [Fixture.gesture(.editBegan)],
            event: Fixture.gesture(.cancel),
            effects: discardEffects + [.setTapPolicy(Fixture.policy(swallowsEscape: false))],
            hud: .hidden,
            isLive: false,
        ),
        ReducerCase(
            "late selection after a discard is dropped",
            setup: [Fixture.gesture(.editBegan), Fixture.gesture(.cancel)],
            event: Fixture.input(.selection(.text("late"))),
            effects: [],
            hud: .hidden,
            isLive: false,
        ),
    ]

    @Test(arguments: editCases)
    func editPaths(_ scenario: ReducerCase) {
        scenario.check()
    }
}
