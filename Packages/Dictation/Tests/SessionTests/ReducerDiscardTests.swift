import Core
import Foundation
@testable import Session
import Testing

internal struct ReducerDiscardTests {
    private static let orphan = URL(fileURLWithPath: "/tmp/audio/\(Fixture.first.stem).caf")
    private static let launched = Event.request(.launched(orphans: [orphan], at: Fixture.date))

    private static func pendingItem(finalText: String, status: HistoryItem.Status) -> HistoryItem {
        Fixture.item(raw: finalText, final: finalText, status: status)
    }

    @Test
    func abandonedDictationDeletesItsAudioThroughTheDiscardEffect() {
        let result = Fixture.play([Script.tapOnly, Fixture.gesture(.abandon)])
        #expect(result.effects.contains(.discardCapture(Fixture.first)))
        #expect(!result.effects.contains(.stopCapture(Fixture.first)))
    }

    @Test
    func holdWithoutSpeechDeletesTheAudio() {
        let events =
            Fixture.holdAndRelease() + [
                Fixture.gesture(.released),
                Fixture.input(.segmentsEnded),
                Fixture.input(.finished(audioURL: Fixture.audioURL)),
            ]
        let result = Fixture.play(events)
        #expect(result.effects.contains(.discardAudio(Fixture.audioURL)))
        #expect(result.state.hud == .noSpeech)
        #expect(result.state.lastResult == nil)
    }

    @Test
    func lockedSessionWithoutSpeechDeletesTheAudio() {
        let events =
            Fixture.holdAndRelease() + [
                .system(.screenLocked),
                Fixture.input(.segmentsEnded),
                Fixture.input(.finished(audioURL: Fixture.audioURL)),
            ]
        #expect(Fixture.play(events).effects.contains(.discardAudio(Fixture.audioURL)))
    }

    @Test
    func orphanWithoutSpeechIsDeleted() {
        let result = Fixture.play([Self.launched, Fixture.input(.segmentsEnded)])
        #expect(result.effects == [.discardAudio(Self.orphan)])
        #expect(result.state.isIdle)
    }

    @Test
    func pendingItemWithoutSpeechIsMarkedFailedAndKeepsItsAudio() {
        let item = Self.pendingItem(finalText: "", status: .pending)
        let result = Fixture.play([
            .request(.modelReady(.speech, pending: [item])),
            Fixture.input(.segmentsEnded),
        ])
        let failed = Fixture.item(raw: "", final: "", status: .failed)
        #expect(result.effects == [.update(failed)])
        #expect(!result.effects.contains(.discardAudio(Fixture.audioURL)))
        #expect(result.state.hud == .hidden)
        #expect(result.state.isIdle)
    }

    @Test
    func retryWithoutSpeechLeavesAnItemThatAlreadyHasTextAlone() {
        let item = Self.pendingItem(finalText: "kept", status: .inserted)
        let result = Fixture.play([.request(.retry(item)), Fixture.input(.segmentsEnded)])
        #expect(result.effects.isEmpty)
        #expect(result.state.isIdle)
    }

    @Test
    func unreadableOrphanIsSavedAsFailedWithItsAudio() {
        let failure = ResultEvent.failed(.speech(.failed(code: 1)))
        let result = Fixture.play([Self.launched, Fixture.result(failure)])
        let expected = HistoryItem(
            id: Fixture.first,
            date: Fixture.date,
            appBundleID: "",
            appName: "",
            kind: .dictation,
            rawText: "",
            finalText: "",
            instruction: nil,
            audioURL: Self.orphan,
            duration: .zero,
            status: .failed,
        )
        #expect(result.effects == [.save(expected)])
        #expect(result.state.hud == .hidden)
        #expect(result.state.isIdle)
    }

    @Test
    func retryResultKeepsTheRealStatusOfAnInsertedItem() {
        let item = Self.pendingItem(finalText: "old", status: .copied)
        let events: [Event] = [
            .request(.retry(item)),
            Fixture.input(.segment(Fixture.segment(0))),
            Fixture.input(.segmentsEnded),
            Fixture.transcribed(0, "fresh"),
            Fixture.cleaned(0, "Fresh."),
        ]
        let result = Fixture.play(events)
        #expect(
            result.effects == [
                .update(Fixture.item(raw: "fresh", final: "Fresh.", status: .copied))
            ]
        )
    }

    @Test
    func retryResultOfAFailedItemIsRecovered() {
        let item = Self.pendingItem(finalText: "", status: .failed)
        let events: [Event] = [
            .request(.retry(item)),
            Fixture.input(.segment(Fixture.segment(0))),
            Fixture.input(.segmentsEnded),
            Fixture.transcribed(0, "fresh"),
            Fixture.cleaned(0, "Fresh."),
        ]
        let result = Fixture.play(events)
        #expect(
            result.effects == [
                .update(Fixture.item(raw: "fresh", final: "Fresh.", status: .recovered))
            ]
        )
    }

    @Test
    func cancelledTranscriptionFailsTheDictationInsteadOfBlockingTheQueue() {
        let events =
            Fixture.holdAndRelease() + [
                Fixture.input(.segment(Fixture.segment(0))),
                Fixture.gesture(.released),
                Fixture.input(.segmentsEnded),
                Fixture.result(.transcribed(index: 0, result: .failure(.cancelled))),
                Fixture.input(.finished(audioURL: Fixture.audioURL)),
            ]
        let result = Fixture.play(events)
        #expect(result.state.hud == .problem(.couldNotTranscribe))
        #expect(result.state.isIdle)
        #expect(result.effects.contains(.save(Fixture.item(raw: "", final: "", status: .failed))))
    }
}
