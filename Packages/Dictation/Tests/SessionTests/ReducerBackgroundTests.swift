import Core
import Foundation
@testable import Session
import Testing

internal struct ReducerBackgroundTests {
    private static let url = URL(fileURLWithPath: "/tmp/audio/one.caf")
    private static let secondURL = URL(fileURLWithPath: "/tmp/audio/two.caf")

    private static func pendingItem(
        _ id: DictationID,
        at seconds: TimeInterval,
        audioURL: URL?,
    ) -> HistoryItem {
        HistoryItem(
            id: id,
            date: Date(timeIntervalSince1970: seconds),
            appBundleID: "com.example.mail",
            appName: "Mail",
            kind: .dictation,
            rawText: "",
            finalText: "",
            instruction: nil,
            audioURL: audioURL,
            duration: .seconds(4),
            status: .pending,
        )
    }

    private static func segmentsAndText(_ id: DictationID, _ text: String) -> [Event] {
        [
            Fixture.input(.segment(Fixture.segment(0, id)), id),
            Fixture.input(.segmentsEnded, id),
            Fixture.transcribed(0, text, id),
        ]
    }

    @Test
    func orphanAudioIsTranscribedAndSavedAsRecovered() {
        let orphan = URL(fileURLWithPath: "/tmp/audio/\(Fixture.first.stem).caf")
        let launched = Fixture.play([
            .request(.launched(orphans: [orphan], at: Fixture.date))
        ])
        #expect(launched.effects == [.readAudio(Fixture.first, orphan)])
        #expect(launched.state.hud == .hidden)
        var state = launched.state
        for event in Self.segmentsAndText(Fixture.first, "recovered words") {
            _ = reduce(&state, event)
        }
        let effects = reduce(&state, Fixture.cleaned(0, "Recovered words.", Fixture.first))
        let expected = HistoryItem(
            id: Fixture.first,
            date: Fixture.date,
            appBundleID: "",
            appName: "",
            kind: .dictation,
            rawText: "recovered words",
            finalText: "Recovered words.",
            instruction: nil,
            audioURL: orphan,
            duration: .seconds(1),
            status: .recovered,
        )
        #expect(effects == [.save(expected)])
        #expect(state.lastResult == nil)
        #expect(state.isIdle)
    }

    @Test
    func orphanWithAnUnreadableNameIsIgnored() {
        let junk = URL(fileURLWithPath: "/tmp/audio/not-an-id.caf")
        let result = Fixture.play([.request(.launched(orphans: [junk], at: Fixture.date))])
        #expect(result.effects.isEmpty)
        #expect(result.state.isIdle)
    }

    @Test
    func orphanAlreadyQueuedIsNotQueuedTwice() {
        let orphan = URL(fileURLWithPath: "/tmp/audio/\(Fixture.first.stem).caf")
        let event = Event.request(.launched(orphans: [orphan], at: Fixture.date))
        let result = Fixture.play([event, event])
        #expect(result.effects.isEmpty)
        #expect(result.state.queue.count == 1)
    }

    @Test
    func speechModelReadyQueuesPendingItemsOldestFirst() {
        let newer = Self.pendingItem(Fixture.second, at: 200, audioURL: Self.secondURL)
        let older = Self.pendingItem(Fixture.first, at: 100, audioURL: Self.url)
        let result = Fixture.play([.request(.modelReady(.speech, pending: [newer, older]))])
        #expect(result.effects == [.readAudio(Fixture.first, Self.url)])
        #expect(result.state.queue.map(\.id) == [Fixture.first, Fixture.second])
    }

    @Test
    func pendingResultUpdatesTheItemAndStartsTheNext() {
        let newer = Self.pendingItem(Fixture.second, at: 200, audioURL: Self.secondURL)
        let older = Self.pendingItem(Fixture.first, at: 100, audioURL: Self.url)
        var state = Fixture.play([.request(.modelReady(.speech, pending: [newer, older]))]).state
        for event in Self.segmentsAndText(Fixture.first, "hello") {
            _ = reduce(&state, event)
        }
        let effects = reduce(&state, Fixture.cleaned(0, "Hello.", Fixture.first))
        let updated = HistoryItem(
            id: Fixture.first,
            date: Date(timeIntervalSince1970: 100),
            appBundleID: "com.example.mail",
            appName: "Mail",
            kind: .dictation,
            rawText: "hello",
            finalText: "Hello.",
            instruction: nil,
            audioURL: Self.url,
            duration: .seconds(1),
            status: .recovered,
        )
        #expect(effects == [.update(updated), .readAudio(Fixture.second, Self.secondURL)])
        #expect(!effects.contains { if case .insert = $0 { true } else { false } })
        #expect(state.hud == .hidden)
    }

    @Test
    func cleanupModelReadyQueuesNothing() {
        let item = Self.pendingItem(Fixture.first, at: 100, audioURL: Self.url)
        let result = Fixture.play([.request(.modelReady(.cleanup, pending: [item]))])
        #expect(result.effects.isEmpty)
        #expect(result.state.isIdle)
    }

    @Test
    func retryRunsTheAudioAgainAndNeverInserts() {
        let item = Fixture.item(raw: "old", final: "old text", status: .inserted)
        var state = Fixture.play([.request(.retry(item))]).state
        #expect(state.queue.count == 1)
        for event in Self.segmentsAndText(Fixture.first, "fresh") {
            _ = reduce(&state, event)
        }
        let effects = reduce(&state, Fixture.cleaned(0, "Fresh.", Fixture.first))
        let expected = Fixture.item(
            raw: "fresh",
            final: "Fresh.",
            status: .inserted,
        )
        #expect(effects == [.update(expected)])
    }

    @Test
    func retryEmitsTheAudioRead() {
        let item = Fixture.item(raw: "old", final: "old text", status: .failed)
        #expect(
            Fixture.play([.request(.retry(item))]).effects == [
                .readAudio(Fixture.first, Fixture.audioURL)
            ]
        )
    }

    @Test
    func retryWithoutAudioIsIgnored() {
        let item = Fixture.item(raw: "old", final: "old", status: .failed, audioURL: nil)
        let result = Fixture.play([.request(.retry(item))])
        #expect(result.effects.isEmpty)
        #expect(result.state.isIdle)
    }

    @Test
    func backgroundModelFailureKeepsTheItemPendingWithoutAHUD() {
        let item = Self.pendingItem(Fixture.first, at: 100, audioURL: Self.url)
        var state = Fixture.play([.request(.modelReady(.speech, pending: [item]))]).state
        _ = reduce(
            &state,
            Fixture.input(.segment(Fixture.segment(0, Fixture.first)), Fixture.first),
        )
        _ = reduce(&state, Fixture.input(.segmentsEnded, Fixture.first))
        let effects = reduce(
            &state,
            Fixture.result(
                .transcribed(index: 0, result: .failure(.modelUnavailable)),
                Fixture.first,
            ),
        )
        #expect(effects.count == 1)
        guard case .update(let kept) = effects.first else {
            Issue.record("expected an update")
            return
        }
        #expect(kept.status == .pending)
        #expect(state.hud == .hidden)
    }
}
