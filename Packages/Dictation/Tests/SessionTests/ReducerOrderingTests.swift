import Core
@testable import Session
import Testing

internal struct ReducerOrderingTests {
    private static let orderingCases: [ReducerCase] = [
        ReducerCase(
            "segment is transcribed as soon as it closes",
            setup: Script.live,
            event: Fixture.input(.segment(Fixture.segment(0))),
            effects: [Script.transcribeEffect(0)],
            hud: .listening,
            isLive: true,
        ),
        ReducerCase(
            "second segment is transcribed without waiting for the first",
            setup: Script.live + [Fixture.input(.segment(Fixture.segment(0)))],
            event: Fixture.input(.segment(Fixture.segment(1))),
            effects: [Script.transcribeEffect(1)],
            hud: .listening,
            isLive: true,
        ),
        ReducerCase(
            "first transcription starts its cleaning",
            setup: Script.liveWithSegments,
            event: Fixture.transcribed(0, "hello"),
            effects: [
                .clean(
                    Fixture.first,
                    index: 0,
                    input: CleanInput(
                        text: "hello",
                        contextBefore: "",
                        isFinalSegment: false,
                    ),
                )
            ],
            hud: .listening,
            isLive: true,
        ),
        ReducerCase(
            "the last open segment waits until the capture ends",
            setup: Script.live + [Fixture.input(.segment(Fixture.segment(0)))],
            event: Fixture.transcribed(0, "hello"),
            effects: [],
            hud: .listening,
            isLive: true,
        ),
        ReducerCase(
            "ending the capture releases the last segment as final",
            setup: Script.live + [
                Fixture.input(.segment(Fixture.segment(0))), Fixture.gesture(.released),
                Fixture.transcribed(0, "hello"),
            ],
            event: Fixture.input(.segmentsEnded),
            effects: [
                .clean(
                    Fixture.first,
                    index: 0,
                    input: CleanInput(
                        text: "hello",
                        contextBefore: "",
                        isFinalSegment: true,
                    ),
                )
            ],
            hud: .hidden,
            isLive: false,
        ),
        ReducerCase(
            "cleaning waits for the previous cleaned segment",
            setup: Script.liveWithSegments + [Fixture.transcribed(0, "hello")],
            event: Fixture.transcribed(1, "world"),
            effects: [],
            hud: .listening,
            isLive: true,
        ),
        ReducerCase(
            "cleaned segment releases the next with cleaned context",
            setup: Script.liveWithSegments + [
                Fixture.gesture(.released), Fixture.input(.segmentsEnded),
                Fixture.transcribed(0, "hello"), Fixture.transcribed(1, "world"),
            ],
            event: Fixture.cleaned(0, "Hello."),
            effects: [
                .clean(
                    Fixture.first,
                    index: 1,
                    input: CleanInput(
                        text: "world",
                        contextBefore: "Hello.",
                        isFinalSegment: true,
                    ),
                )
            ],
            hud: .hidden,
            isLive: false,
        ),
        ReducerCase(
            "text before the cursor is the first segment context",
            setup: Fixture.holdAndRelease(
                focus: FocusSnapshot(
                    target: Fixture.app,
                    fieldKind: .multiLine,
                    fieldID: 1,
                    isSecure: false,
                    isComposing: false,
                    textBefore: "Dear team,",
                )
            ) + [
                Fixture.input(.segment(Fixture.segment(0))),
                Fixture.gesture(.released), Fixture.input(.segmentsEnded),
            ],
            event: Fixture.transcribed(0, "hello"),
            effects: [
                .clean(
                    Fixture.first,
                    index: 0,
                    input: CleanInput(
                        text: "hello",
                        contextBefore: "Dear team,",
                        isFinalSegment: true,
                    ),
                )
            ],
            hud: .hidden,
            isLive: false,
        ),
        ReducerCase(
            "failed cleanup falls back to the raw text",
            setup: Script.liveWithSegments + [Fixture.transcribed(0, "hello")],
            event: Fixture.result(.cleaned(index: 0, result: .failure(.timedOut))),
            effects: [],
            hud: .listening,
            isLive: true,
        ),
        ReducerCase(
            "result for an unknown dictation is dropped",
            setup: Script.live,
            event: Fixture.transcribed(0, "stale", Fixture.third),
            effects: [],
            hud: .listening,
            isLive: true,
        ),
    ]

    @Test(arguments: orderingCases)
    func segmentOrdering(_ scenario: ReducerCase) {
        scenario.check()
    }

    @Test
    func failedCleanupInsertsTheRawText() {
        let events =
            Script.liveWithSegments + [
                Fixture.gesture(.released),
                Fixture.input(.segmentsEnded),
                Fixture.transcribed(0, "hello"),
                Fixture.result(.cleaned(index: 0, result: .failure(.timedOut))),
                Fixture.transcribed(1, "world"),
                Fixture.result(.cleaned(index: 1, result: .failure(.rejected))),
                Fixture.input(.finished(audioURL: Fixture.audioURL)),
            ]
        #expect(
            Fixture.play(events).effects == [
                .insert(Fixture.first, text: "hello world", focus: Fixture.focus)
            ]
        )
    }
}
