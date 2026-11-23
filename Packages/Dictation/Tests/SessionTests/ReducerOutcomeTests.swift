import Core
@testable import Session
import Testing

internal struct ReducerOutcomeTests {
    private static let outcomeCases: [ReducerCase] = [
        ReducerCase(
            "inserted dictation is saved and observed for learning",
            setup: Fixture.finishedDictation(["Hello.", "World."]),
            event: Fixture.result(.inserted(.inserted(.pasteShortcut))),
            effects: [
                .save(
                    Fixture.item(
                        raw: "Hello. World.",
                        final: "Hello. World.",
                        status: .inserted,
                        duration: .seconds(2),
                    )
                ),
                .observeForLearning(text: "Hello. World.", focus: Fixture.focus),
                .cancelTimer(.processingDelay),
            ],
            hud: .hidden,
            isLive: false,
        ),
        ReducerCase(
            "lost focus copies the text and shows Copied",
            setup: Fixture.finishedDictation(["Hello."]),
            event: Fixture.result(.inserted(.copied(.targetLostFocus))),
            effects: [
                .copy("Hello."),
                .save(
                    Fixture.item(
                        raw: "Hello.",
                        final: "Hello.",
                        status: .copied,
                        duration: .seconds(1),
                    )
                ),
                .startTimer(.hudExpiry, .seconds(3)),
                .cancelTimer(.processingDelay),
            ],
            hud: .copied,
            isLive: false,
        ),
        ReducerCase(
            "password field is saved as refused without audio and never copied",
            setup: Fixture.finishedDictation(["secret"]),
            event: Fixture.result(.inserted(.refused(.secureField))),
            effects: [
                .save(
                    Fixture.item(
                        raw: "secret",
                        final: "secret",
                        status: .refused,
                        duration: .seconds(1),
                        audioURL: nil,
                    )
                ),
                .discardAudio(Fixture.audioURL),
                .startTimer(.hudExpiry, .seconds(8)),
                .cancelTimer(.processingDelay),
            ],
            hud: .problem(.passwordField),
            isLive: false,
        ),
        ReducerCase(
            "missing speech model saves the dictation for later",
            setup: Fixture.holdAndRelease() + [
                Fixture.input(.segment(Fixture.segment(0))), Fixture.gesture(.released),
                Fixture.result(.transcribed(index: 0, result: .failure(.modelUnavailable))),
                Fixture.input(.segmentsEnded),
            ],
            event: Fixture.input(.finished(audioURL: Fixture.audioURL)),
            effects: [
                .save(
                    Fixture.item(raw: "", final: "", status: .pending, duration: .seconds(1))
                ),
                .startTimer(.hudExpiry, .seconds(2)),
                .cancelTimer(.processingDelay),
            ],
            hud: .saved,
            isLive: false,
        ),
        ReducerCase(
            "speech failure shows a problem and keeps the audio",
            setup: Fixture.holdAndRelease() + [
                Fixture.input(.segment(Fixture.segment(0))), Fixture.gesture(.released),
                Fixture.result(.transcribed(index: 0, result: .failure(.failed(code: 1)))),
                Fixture.input(.segmentsEnded),
            ],
            event: Fixture.input(.finished(audioURL: Fixture.audioURL)),
            effects: [
                .save(
                    Fixture.item(raw: "", final: "", status: .failed, duration: .seconds(1))
                ),
                .startTimer(.hudExpiry, .seconds(8)),
                .cancelTimer(.processingDelay),
            ],
            hud: .problem(.couldNotTranscribe),
            isLive: false,
        ),
    ]

    @Test(arguments: outcomeCases)
    func outcomes(_ scenario: ReducerCase) {
        scenario.check()
    }

    @Test
    func secureResultStaysAsLastResult() throws {
        let events =
            Fixture.finishedDictation(["secret"]) + [
                Fixture.result(.inserted(.refused(.secureField)))
            ]
        let last = try #require(Fixture.play(events).state.lastResult)
        #expect(last.item.finalText == "secret")
    }
}
