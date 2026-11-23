import Core
@testable import Session
import Testing

internal struct ReducerEditTests {
    private static let first = Fixture.first
    private static let focus = Fixture.focus
    private static let editing: [Event] = [
        Fixture.gesture(.editBegan),
        Fixture.input(.focus(focus)),
        Fixture.input(.selection(.text("long selected text"))),
        Fixture.input(.started),
        Fixture.input(.segment(Fixture.segment(0))),
        Fixture.gesture(.released),
        Fixture.transcribed(0, "make it shorter"),
        Fixture.input(.segmentsEnded),
    ]

    private static func editedItem(final: String, status: HistoryItem.Status) -> HistoryItem {
        HistoryItem(
            id: first,
            date: Fixture.date,
            appBundleID: Fixture.app.bundleID,
            appName: Fixture.app.name,
            kind: .edit,
            rawText: "long selected text",
            finalText: final,
            instruction: "make it shorter",
            audioURL: Fixture.audioURL,
            duration: .seconds(1),
            status: status,
        )
    }

    @Test
    func instructionIsSentToTheEditorOnceRecognized() {
        let state = Fixture.play(Array(Self.editing.dropLast()))
        let ended = Fixture.play([Fixture.input(.segmentsEnded)], from: state.state)
        #expect(
            ended.effects == [
                .edit(Self.first, selection: "long selected text", instruction: "make it shorter")
            ]
        )
    }

    @Test
    func instructionIsNotCleanedAsText() {
        let result = Fixture.play(Array(Self.editing.dropLast()))
        #expect(!result.effects.contains { if case .clean = $0 { true } else { false } })
    }

    @Test
    func rewrittenTextReplacesTheSelection() {
        let events =
            Self.editing + [
                Fixture.input(.finished(audioURL: Fixture.audioURL)),
                Fixture.result(.edited(.success("short"))),
            ]
        #expect(
            Fixture.play(events).effects == [.insert(Self.first, text: "short", focus: Self.focus)]
        )
    }

    @Test
    func insertedEditIsSavedWithItsInstruction() {
        let events =
            Self.editing + [
                Fixture.input(.finished(audioURL: Fixture.audioURL)),
                Fixture.result(.edited(.success("short"))),
                Fixture.result(.inserted(.inserted(.pasteShortcut))),
            ]
        let effects = Fixture.play(events).effects
        #expect(effects.first == .save(Self.editedItem(final: "short", status: .inserted)))
        #expect(!effects.contains { if case .observeForLearning = $0 { true } else { false } })
    }

    @Test
    func failedEditShowsCouldNotEditAndKeepsTheInstruction() {
        let events =
            Self.editing + [
                Fixture.input(.finished(audioURL: Fixture.audioURL)),
                Fixture.result(.edited(.failure(.rejected))),
            ]
        let result = Fixture.play(events)
        #expect(
            result.effects == [
                .save(Self.editedItem(final: "", status: .failed)),
                .startTimer(.hudExpiry, .seconds(8)),
                .cancelTimer(.processingDelay),
            ]
        )
        #expect(result.state.hud == .problem(.couldNotEdit))
        #expect(result.state.lastResult == nil)
        #expect(!result.effects.contains { if case .insert = $0 { true } else { false } })
    }

    @Test
    func cancelledEditResultFailsTheEditInsteadOfHanging() {
        let events =
            Self.editing + [
                Fixture.input(.finished(audioURL: Fixture.audioURL)),
                Fixture.result(.edited(.failure(.cancelled))),
            ]
        let result = Fixture.play(events)
        #expect(result.state.hud == .problem(.couldNotEdit))
        #expect(result.state.isIdle)
        #expect(!result.effects.contains { if case .insert = $0 { true } else { false } })
    }

    @Test
    func editWithoutSelectionInsertsPlainDictation() {
        let events: [Event] = [
            Fixture.gesture(.editBegan),
            Fixture.input(.focus(Self.focus)),
            Fixture.input(.selection(.none)),
            Fixture.input(.segment(Fixture.segment(0))),
            Fixture.gesture(.released),
            Fixture.input(.segmentsEnded),
            Fixture.transcribed(0, "hello"),
            Fixture.cleaned(0, "Hello."),
            Fixture.input(.finished(audioURL: Fixture.audioURL)),
        ]
        #expect(
            Fixture.play(events).effects == [
                .insert(Self.first, text: "Hello.", focus: Self.focus)
            ]
        )
    }
}
