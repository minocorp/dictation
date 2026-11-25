import Core
@testable import Session
import Testing

internal struct ReducerCancelTests {
    private static let cancelCases: [ReducerCase] = [
        ReducerCase(
            "cancel while capturing shows Canceled for 5 seconds",
            setup: [Script.tapOnly, .timer(.tapThreshold)],
            event: Fixture.gesture(.cancel),
            effects: [
                .cancelWork(Fixture.first),
                .stopCapture(Fixture.first),
                .play(.cancel),
                .startTimer(.hudExpiry, .seconds(5)),
                .setTapPolicy(Fixture.policy(swallowsEscape: false)),
            ],
            hud: .canceled,
            isLive: false,
        ),
        ReducerCase(
            "cancel before the tap threshold stops its timer",
            setup: [Script.tapOnly],
            event: Fixture.gesture(.cancel),
            effects: [
                .cancelTimer(.tapThreshold),
                .cancelWork(Fixture.first),
                .stopCapture(Fixture.first),
                .play(.cancel),
                .startTimer(.hudExpiry, .seconds(5)),
                .setTapPolicy(Fixture.policy(swallowsEscape: false)),
            ],
            hud: .canceled,
            isLive: false,
        ),
        ReducerCase(
            "cancel with sounds off plays nothing",
            setup: [Script.soundsOff, Script.tapOnly, .timer(.tapThreshold)],
            event: Fixture.gesture(.cancel),
            effects: [
                .cancelWork(Fixture.first),
                .stopCapture(Fixture.first),
                .startTimer(.hudExpiry, .seconds(5)),
                .setTapPolicy(Fixture.policy(swallowsEscape: false)),
            ],
            hud: .canceled,
            isLive: false,
        ),
        ReducerCase(
            "cancel with nothing live is ignored",
            event: Fixture.gesture(.cancel),
            effects: [],
            hud: .hidden,
            isLive: false,
        ),
        ReducerCase(
            "notice expiry hides the HUD",
            setup: [Script.tapOnly, Fixture.gesture(.cancel)],
            event: .timer(.hudExpiry),
            effects: [],
            hud: .hidden,
            isLive: false,
        ),
    ]

    private static let abandonCases: [ReducerCase] = [
        ReducerCase(
            "abandon while holding discards silently with no HUD",
            setup: [Script.tapOnly],
            event: Fixture.gesture(.abandon),
            effects: [
                .cancelTimer(.tapThreshold),
                .cancelWork(Fixture.first),
                .discardCapture(Fixture.first),
                .setTapPolicy(Fixture.policy(swallowsEscape: false)),
            ],
            hud: .hidden,
            isLive: false,
        ),
        ReducerCase(
            "abandon after the tap threshold discards silently",
            setup: [Script.tapOnly, .timer(.tapThreshold)],
            event: Fixture.gesture(.abandon),
            effects: [
                .cancelWork(Fixture.first),
                .discardCapture(Fixture.first),
                .setTapPolicy(Fixture.policy(swallowsEscape: false)),
            ],
            hud: .hidden,
            isLive: false,
        ),
        ReducerCase(
            "abandon with nothing live is ignored",
            event: Fixture.gesture(.abandon),
            effects: [],
            hud: .hidden,
            isLive: false,
        ),
    ]

    @Test(arguments: abandonCases)
    func abandonPaths(_ scenario: ReducerCase) {
        scenario.check()
    }

    @Test
    func abandonedDictationLeavesNoHistoryAndBecomesIdleOnceAudioCloses() {
        let events = [Script.tapOnly, Fixture.gesture(.abandon)]
        let closed = Fixture.play(events + [Fixture.input(.finished(audioURL: Fixture.audioURL))])
        #expect(closed.state.lastResult == nil)
        #expect(closed.effects.isEmpty)
        #expect(closed.state.isIdle)
    }

    @Test(arguments: cancelCases)
    func cancelPaths(_ scenario: ReducerCase) {
        scenario.check()
    }

    @Test
    func canceledDictationBecomesTheLastResultOnceAudioCloses() throws {
        let events = Fixture.holdAndRelease() + [Fixture.gesture(.cancel)]
        let closed = Fixture.play(events + [Fixture.input(.finished(audioURL: Fixture.audioURL))])
        let last = try #require(closed.state.lastResult)
        #expect(last.item.status == .canceled)
        #expect(last.item.audioURL == Fixture.audioURL)
        #expect(last.item.finalText.isEmpty)
        #expect(last.target == Fixture.focus)
        #expect(closed.effects == [.save(last.item)])
        #expect(closed.state.isIdle)
    }

    @Test
    func canceledDictationWaitsForAudioBeforeBecomingIdle() {
        let canceled = Fixture.play(Fixture.holdAndRelease() + [Fixture.gesture(.cancel)])
        #expect(canceled.state.lastResult == nil)
        #expect(!canceled.state.isIdle)
    }
}
