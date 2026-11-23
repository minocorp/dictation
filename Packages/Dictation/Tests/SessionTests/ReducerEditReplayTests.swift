import Core
@testable import Session
import Testing

internal struct ReducerEditReplayTests {
    private static let canceledEdit: [Event] = [
        Fixture.gesture(.editBegan),
        Fixture.input(.focus(Fixture.focus)),
        Fixture.input(.started),
        Fixture.input(.selection(.text("long selected text"))),
        Fixture.gesture(.cancel),
        Fixture.input(.segmentsEnded),
        Fixture.input(.finished(audioURL: Fixture.audioURL)),
    ]

    @Test
    func canceledEditIsKeptAsAnEditWithItsSelection() throws {
        let last = try #require(Fixture.play(Self.canceledEdit).state.lastResult)
        #expect(last.item.kind == .edit)
        #expect(last.item.rawText == "long selected text")
        #expect(last.item.status == .canceled)
        #expect(last.item.finalText.isEmpty)
    }

    @Test
    func restoreOfACanceledEditShowsAProblemAndNeverReadsTheInstruction() {
        let before = Fixture.play(Self.canceledEdit).state
        let result = Fixture.play([Fixture.gesture(.restore, Fixture.second)], from: before)
        #expect(result.state.hud == .problem(.couldNotEdit))
        #expect(!result.effects.contains { if case .readAudio = $0 { true } else { false } })
        #expect(result.state.queue.isEmpty)
        #expect(result.state.lastResult == before.lastResult)
    }

    @Test
    func pasteLastOfACanceledEditShowsAProblemInsteadOfPastingTheInstruction() {
        let before = Fixture.play(Self.canceledEdit).state
        let events: [Event] = [
            Fixture.gesture(.pasteLast, Fixture.second),
            Fixture.input(.focus(Fixture.focus), Fixture.second),
        ]
        let result = Fixture.play(events, from: before)
        #expect(result.state.hud == .problem(.couldNotEdit))
        #expect(result.state.queue.isEmpty)
        #expect(!result.effects.contains { if case .readAudio = $0 { true } else { false } })
    }
}
