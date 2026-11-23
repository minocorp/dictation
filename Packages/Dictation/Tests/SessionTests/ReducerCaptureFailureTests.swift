import Core
@testable import Session
import Testing

internal struct ReducerCaptureFailureTests {
    private static let untrusted = PermissionStatus(
        microphone: .granted,
        isAccessibilityTrusted: false,
    )
    private static let denied = PermissionStatus(microphone: .denied, isAccessibilityTrusted: true)

    private static func failedItem() -> HistoryItem {
        Fixture.item(raw: "", final: "", status: .failed, duration: .zero)
    }

    @Test(arguments: [
        (CaptureError.engineFailed(code: 1), Problem.microphoneUnavailable),
        (.noInputDevice, .microphoneUnavailable),
        (.diskWriteFailed(code: 28), .couldNotSave),
    ])
    func failureWhileCapturingStopsKeepsTheAudioAndShowsAProblem(
        error: CaptureError,
        problem: Problem,
    ) {
        let live = Fixture.play(Fixture.holdAndRelease())
        let failed = Fixture.play([Fixture.result(.failed(.capture(error)))], from: live.state)
        #expect(failed.effects.contains(.stopCapture(Fixture.first)))
        #expect(!failed.state.isLive)
        let closed = Fixture.play(
            [
                Fixture.input(.segmentsEnded),
                Fixture.input(.finished(audioURL: Fixture.audioURL)),
            ],
            from: failed.state,
        )
        #expect(closed.effects.contains(.save(Self.failedItem())))
        #expect(closed.state.hud == .problem(problem))
        #expect(closed.state.lastResult?.item.audioURL == Fixture.audioURL)
        #expect(closed.state.isIdle)
    }

    @Test
    func failureDuringHandsFreeStopsTheTickTimerAndCapture() {
        let live = Fixture.play(Script.handsFree + [Fixture.input(.started)])
        let failed = Fixture.play(
            [Fixture.result(.failed(.capture(.engineFailed(code: 1))))],
            from: live.state,
        )
        #expect(failed.effects.contains(.cancelTimer(.handsFreeSecond)))
        #expect(failed.effects.contains(.stopCapture(Fixture.first)))
    }

    @Test
    func cancelledCaptureErrorIsIgnored() {
        let live = Fixture.play(Fixture.holdAndRelease())
        let result = Fixture.play(
            [Fixture.result(.failed(.capture(.cancelled)))],
            from: live.state,
        )
        #expect(result.effects.isEmpty)
        #expect(result.state.isLive)
    }

    @Test
    func failureOfAnEndedCaptureIsIgnored() {
        let ended = Fixture.play(
            Fixture.holdAndRelease() + [Fixture.gesture(.released)]
        )
        let result = Fixture.play(
            [Fixture.result(.failed(.capture(.diskWriteFailed(code: 1))))],
            from: ended.state,
        )
        #expect(result.effects.isEmpty)
    }

    @Test
    func accessibilityLossWhileLiveFinishesAndKeepsTheResultWithoutInserting() {
        let live = Fixture.play(Fixture.holdAndRelease())
        let lost = Fixture.play([.system(.permission(Self.untrusted))], from: live.state)
        #expect(lost.effects.contains(.stopCapture(Fixture.first)))
        #expect(lost.state.hud == .problem(.accessibilityOff))
        let events: [Event] = [
            Fixture.input(.segment(Fixture.segment(0))),
            Fixture.input(.segmentsEnded),
            Fixture.transcribed(0, "hello"),
            Fixture.cleaned(0, "Hello."),
            Fixture.input(.finished(audioURL: Fixture.audioURL)),
        ]
        let done = Fixture.play(events, from: lost.state)
        #expect(!done.effects.contains { if case .insert = $0 { true } else { false } })
        #expect(done.state.lastResult?.item.finalText == "Hello.")
    }

    @Test
    func microphoneLossWhileLiveFinishesWithAFailedItem() {
        let live = Fixture.play(Fixture.holdAndRelease())
        let lost = Fixture.play([.system(.permission(Self.denied))], from: live.state)
        #expect(lost.effects.contains(.stopCapture(Fixture.first)))
        let closed = Fixture.play(
            [
                Fixture.input(.segmentsEnded),
                Fixture.input(.finished(audioURL: Fixture.audioURL)),
            ],
            from: lost.state,
        )
        #expect(closed.state.hud == .problem(.microphoneDenied))
        #expect(closed.effects.contains(.save(Self.failedItem())))
    }

    @Test
    func permissionChangeWithNothingLiveDoesNotTouchCapture() {
        let result = Fixture.play([.system(.permission(Self.untrusted))])
        #expect(result.effects.isEmpty)
    }

    @Test
    func lockingDropsAQueuedPasteLast() {
        let events =
            Fixture.finishedDictation(["Hello."]) + [
                Fixture.gesture(.pasteLast, Fixture.second),
                .system(.screenLocked),
            ]
        let result = Fixture.play(events)
        #expect(result.state.queue.map(\.id) == [Fixture.first])
    }
}
