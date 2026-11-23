import Core
import Foundation
@testable import Session
import Testing

internal struct ReducerQueueTests {
    private static let first = Fixture.first
    private static let second = Fixture.second
    private static let third = Fixture.third
    private static let focus = Fixture.focus
    private static let firstInserted =
        Fixture.finishedDictation(["First."]) + [
            Fixture.result(.inserted(.inserted(.pasteShortcut)))
        ]
    private static let secondProcessing =
        Fixture.holdAndRelease(second) + [
            Fixture.input(.segment(Fixture.segment(0, second)), second),
            Fixture.gesture(.released, second),
        ]
    private static let secondReady: [Event] = [
        Fixture.input(.segmentsEnded, second),
        Fixture.transcribed(0, "Second.", second),
        Fixture.cleaned(0, "Second.", second),
        Fixture.input(.finished(audioURL: Fixture.audioURL), second),
    ]
    private static let canceled =
        Fixture.holdAndRelease() + [
            Fixture.gesture(.cancel),
            Fixture.input(.finished(audioURL: Fixture.audioURL)),
        ]

    private static func inserts(_ effects: [Effect]) -> [Effect] {
        effects.filter { if case .insert = $0 { true } else { false } }
    }

    @Test
    func pasteLastWaitsForTheFocusReadThenInsertsTheLastText() {
        let asked = Fixture.play(
            [Fixture.gesture(.pasteLast, Self.third)],
            from: Fixture.play(Self.firstInserted).state,
        )
        #expect(
            asked.effects == [
                .readFocus(Self.third), .startTimer(.processingDelay, .milliseconds(250)),
            ]
        )
        let focused = Fixture.play(
            [Fixture.input(.focus(Self.focus), Self.third)],
            from: asked.state,
        )
        #expect(focused.effects == [.insert(Self.third, text: "First.", focus: Self.focus)])
    }

    @Test
    func pasteLastNeitherSavesNorReplacesTheLastResult() {
        let events =
            Self.firstInserted + [
                Fixture.gesture(.pasteLast, Self.third),
                Fixture.input(.focus(Self.focus), Self.third),
            ]
        let before = Fixture.play(Self.firstInserted).state.lastResult
        let done = Fixture.play(
            [Fixture.result(.inserted(.inserted(.pasteShortcut)), Self.third)],
            from: Fixture.play(events).state,
        )
        #expect(done.effects == [.cancelTimer(.processingDelay)])
        #expect(done.state.lastResult == before)
        #expect(done.state.isIdle)
    }

    @Test
    func pasteLastWaitsBehindTheQueueAndPastesTheNewestResult() {
        let queued =
            Self.firstInserted + Self.secondProcessing + [
                Fixture.gesture(.pasteLast, Self.third),
                Fixture.input(.focus(Self.focus), Self.third),
            ]
        var state = Fixture.play(queued).state
        #expect(state.queue.count == 2)
        var all: [Effect] = []
        for event in Self.secondReady {
            all += reduce(&state, event)
        }
        #expect(Self.inserts(all) == [.insert(Self.second, text: "Second.", focus: Self.focus)])
        let finished = reduce(
            &state,
            Fixture.result(.inserted(.inserted(.pasteShortcut)), Self.second),
        )
        #expect(
            Self.inserts(finished) == [.insert(Self.third, text: "Second.", focus: Self.focus)]
        )
    }

    @Test
    func pasteLastWithNothingToPasteDoesNothing() {
        let events: [Event] = [
            Fixture.gesture(.pasteLast, Self.third), Fixture.input(.focus(Self.focus), Self.third),
        ]
        let result = Fixture.play(events)
        #expect(result.effects == [.cancelTimer(.processingDelay)])
        #expect(result.state.isIdle)
    }

    @Test
    func pasteLastAfterCancelProcessesTheCanceledAudio() {
        let events =
            Self.canceled + [
                Fixture.gesture(.pasteLast, Self.third),
                Fixture.input(.focus(Self.focus), Self.third),
            ]
        #expect(Fixture.play(events).effects == [.readAudio(Self.third, Fixture.audioURL)])
    }

    @Test
    func restoreProcessesTheCanceledAudio() {
        let result = Fixture.play(
            [Fixture.gesture(.restore, Self.second)],
            from: Fixture.play(Self.canceled).state,
        )
        #expect(
            result.effects == [
                .cancelTimer(.hudExpiry),
                .readAudio(Self.second, Fixture.audioURL),
                .startTimer(.processingDelay, .milliseconds(250)),
            ]
        )
        #expect(result.state.hud == .hidden)
    }

    @Test
    func restoredDictationIsInsertedIntoTheOriginalTargetAndUpdatesHistory() throws {
        let events =
            Self.canceled + [
                Fixture.gesture(.restore, Self.second),
                Fixture.input(.segment(Fixture.segment(0, Self.second)), Self.second),
                Fixture.input(.segmentsEnded, Self.second),
                Fixture.transcribed(0, "again", Self.second),
            ]
        var state = Fixture.play(events).state
        let ready = reduce(&state, Fixture.cleaned(0, "Again.", Self.second))
        #expect(ready == [.insert(Self.second, text: "Again.", focus: Self.focus)])
        let done = reduce(
            &state,
            Fixture.result(.inserted(.copied(.targetLostFocus)), Self.second),
        )
        let expected = Fixture.item(
            Self.first,
            raw: "again",
            final: "Again.",
            status: .copied,
            duration: .seconds(1),
        )
        #expect(done.first == .copy("Again."))
        #expect(done.contains(.update(expected)))
    }

    @Test
    func restoreTwiceQueuesOnce() {
        let once = Fixture.play(
            [Fixture.gesture(.restore, Self.second)],
            from: Fixture.play(Self.canceled).state,
        )
        let twice = Fixture.play([Fixture.gesture(.restore, Self.third)], from: once.state)
        #expect(twice.effects.isEmpty)
        #expect(twice.state.queue.count == 1)
    }

    @Test
    func restoreWithoutACanceledResultDoesNothing() {
        #expect(Fixture.play([Fixture.gesture(.restore, Self.second)]).effects.isEmpty)
    }

    @Test
    func queuedDictationsAreInsertedInOrder() {
        let firstWaiting = Fixture.finishedDictation(["First."])
        let secondDone = Self.secondProcessing + Self.secondReady
        var state = Fixture.play(firstWaiting + secondDone).state
        #expect(state.queue.count == 2)
        let effects = reduce(&state, Fixture.result(.inserted(.inserted(.pasteShortcut))))
        #expect(
            Self.inserts(effects) == [.insert(Self.second, text: "Second.", focus: Self.focus)]
        )
    }

    @Test
    func secondCaptureStartsWhileTheFirstIsDelivering() {
        let state = Fixture.play(Fixture.finishedDictation(["First."])).state
        let result = Fixture.play([Fixture.gesture(.pressBegan, Self.second)], from: state)
        #expect(result.state.hud == .listening)
        #expect(result.effects.contains(.startCapture(Self.second, device: .builtIn)))
    }
}
