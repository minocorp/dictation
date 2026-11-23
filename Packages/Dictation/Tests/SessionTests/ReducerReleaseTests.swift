import Core
@testable import Session
import Testing

internal struct ReducerReleaseTests {
    private static let releaseCases: [ReducerCase] = [
        ReducerCase(
            "release after the tap threshold finishes",
            setup: [Script.tapOnly, .timer(.tapThreshold)],
            event: Fixture.gesture(.released),
            effects: Script.finishEffects,
            hud: .hidden,
            isLive: false,
        ),
        ReducerCase(
            "quick release waits for a double tap",
            setup: [Script.tapOnly],
            event: Fixture.gesture(.released),
            effects: [
                .cancelTimer(.tapThreshold),
                .startTimer(.doubleTapWindow, Script.doubleTapWindow),
            ],
            hud: .listening,
            isLive: true,
        ),
        ReducerCase(
            "double tap window expiry finishes",
            setup: Script.afterTap,
            event: .timer(.doubleTapWindow),
            effects: [.cancelTimer(.doubleTapWindow)] + Script.finishEffects,
            hud: .hidden,
            isLive: false,
        ),
        ReducerCase(
            "double tap enters hands-free",
            setup: Script.afterTap,
            event: Fixture.gesture(.handsFreeBegan),
            effects: [
                .cancelTimer(.doubleTapWindow),
                .startTimer(.handsFreeSecond, .seconds(1)),
            ],
            hud: .handsFree(elapsed: .zero, countdown: nil),
            isLive: true,
        ),
        ReducerCase(
            "release inside hands-free is ignored",
            setup: Script.handsFree,
            event: Fixture.gesture(.released),
            effects: [],
            hud: .handsFree(elapsed: .zero, countdown: nil),
            isLive: true,
        ),
        ReducerCase(
            "hands-free end finishes",
            setup: Script.handsFree,
            event: Fixture.gesture(.handsFreeEnded),
            effects: [.cancelTimer(.handsFreeSecond)] + Script.finishEffects,
            hud: .hidden,
            isLive: false,
        ),
        ReducerCase(
            "stop button finishes",
            setup: Script.handsFree,
            event: Fixture.gesture(.stop),
            effects: [.cancelTimer(.handsFreeSecond)] + Script.finishEffects,
            hud: .hidden,
            isLive: false,
        ),
        ReducerCase(
            "hands-free end without hands-free is ignored",
            setup: [Script.tapOnly, .timer(.tapThreshold)],
            event: Fixture.gesture(.handsFreeEnded),
            effects: [],
            hud: .listening,
            isLive: true,
        ),
        ReducerCase(
            "edit release finishes without a double tap wait",
            setup: [
                Fixture.gesture(.editBegan), Fixture.input(.selection(.text("hello"))),
            ],
            event: Fixture.gesture(.released),
            effects: Script.finishEffects,
            hud: .hidden,
            isLive: false,
        ),
    ]

    @Test(arguments: releaseCases)
    func releasePaths(_ scenario: ReducerCase) {
        scenario.check()
    }
}
