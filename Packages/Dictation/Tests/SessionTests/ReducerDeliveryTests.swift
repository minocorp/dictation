import Core
@testable import Session
import Testing

internal struct ReducerDeliveryTests {
    private static let deliveryCases: [ReducerCase] = [
        ReducerCase(
            "inserts once every segment is cleaned and audio is closed",
            setup: Fixture.finishedDictation(["Hello.", "World."]).dropLast(),
            event: Fixture.input(.finished(audioURL: Fixture.audioURL)),
            effects: [.insert(Fixture.first, text: "Hello. World.", focus: Fixture.focus)],
            hud: .hidden,
            isLive: false,
        ),
        ReducerCase(
            "no insert before the last segment is cleaned",
            setup: Script.liveWithSegments + [
                Fixture.gesture(.released), Fixture.transcribed(0, "a"), Fixture.cleaned(0, "a"),
                Fixture.transcribed(1, "b"), Fixture.input(.segmentsEnded),
            ],
            event: Fixture.input(.finished(audioURL: Fixture.audioURL)),
            effects: [],
            hud: .hidden,
            isLive: false,
        ),
        ReducerCase(
            "unknown target copies instead of inserting",
            setup: Fixture.finishedDictation(["Hello."], focus: nil).dropLast(),
            event: Fixture.input(.finished(audioURL: Fixture.audioURL)),
            effects: [
                .copy("Hello."),
                .save(
                    Fixture.item(
                        raw: "Hello.",
                        final: "Hello.",
                        status: .copied,
                    )
                    .replacingApp(nil)
                ),
                .startTimer(.hudExpiry, .seconds(3)),
                .cancelTimer(.processingDelay),
            ],
            hud: .copied,
            isLive: false,
        ),
        ReducerCase(
            "silence ends with No speech",
            setup: Fixture.holdAndRelease() + [
                Fixture.gesture(.released), Fixture.input(.segmentsEnded),
            ],
            event: Fixture.input(.finished(audioURL: Fixture.audioURL)),
            effects: [
                .discardAudio(Fixture.audioURL),
                .startTimer(.hudExpiry, .milliseconds(1_500)),
                .cancelTimer(.processingDelay),
            ],
            hud: .noSpeech,
            isLive: false,
        ),
        ReducerCase(
            "a quick tap with no speech shows nothing",
            setup: [
                Fixture.gesture(.pressBegan), Fixture.input(.focus(Fixture.focus)),
                Fixture.gesture(.released), .timer(.doubleTapWindow),
                Fixture.input(.segmentsEnded),
            ],
            event: Fixture.input(.finished(audioURL: Fixture.audioURL)),
            effects: [.discardAudio(Fixture.audioURL), .cancelTimer(.processingDelay)],
            hud: .hidden,
            isLive: false,
        ),
    ]

    @Test(arguments: deliveryCases)
    func deliveryDecisions(_ scenario: ReducerCase) {
        scenario.check()
    }

    @Test
    func startingNewCaptureDuringProcessingKeepsTheOlderOneQueued() {
        let events = Fixture.holdAndRelease() + [Fixture.gesture(.released)]
        let queued = Fixture.play(events).state
        let next = Fixture.play([Fixture.gesture(.pressBegan, Fixture.second)], from: queued)
        #expect(next.state.isLive)
        #expect(next.state.hud == .listening)
        #expect(next.state.queue.count == 1)
        #expect(
            next.effects == [
                .readFocus(Fixture.second),
                .startCapture(Fixture.second, device: .builtIn),
                .startTimer(.tapThreshold, .milliseconds(300)),
                .setTapPolicy(Fixture.policy(swallowsEscape: true)),
            ]
        )
    }

    @Test
    func processingShowsOnlyAfterTheDelay() {
        let events = Fixture.holdAndRelease() + [Fixture.gesture(.released)]
        let queued = Fixture.play(events).state
        #expect(queued.hud == .hidden)
        #expect(Fixture.play([.timer(.processingDelay)], from: queued).state.hud == .processing)
    }
}
