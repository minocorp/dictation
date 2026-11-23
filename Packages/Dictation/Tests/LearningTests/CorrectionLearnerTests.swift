import Clocks
import Core
import CoreTesting
@testable import Learning
import Testing

private typealias ManualClock = Clocks.TestClock<Duration>

internal struct CorrectionLearnerTests {
    private static let target = TargetApp(pid: 7, bundleID: "com.example.notes", name: "Notes")
    private static let inserted = "I use super base daily"
    private static let before = "Notes: I use super base daily"
    private static let after = "Notes: I use Supabase daily"

    private let words = FakeWordStore()

    @Test
    func recordsARespellingWhenFocusLeaves() async {
        let field = FakeField(texts: [Self.before, Self.after], events: [.focusLeft])
        await observe(field: field)
        #expect(field.isClosed)
        #expect(words.words.isEmpty)
        await observe(field: FakeField(texts: [Self.before, Self.after], events: [.focusLeft]))
        #expect(
            words.words == [Word(text: "Supabase", soundsLike: ["super base"], source: .learned)]
        )
    }

    @Test(arguments: [FieldEvent.focusLeft, .appDeactivated])
    func everyEndingEventReadsTheFinalText(event: FieldEvent) async {
        for _ in 0..<2 {
            await observe(field: FakeField(texts: [Self.before, Self.after], events: [event]))
        }
        #expect(words.words.map(\.text) == ["Supabase"])
    }

    @Test
    func usesTheLatestValueWhenTheFinalReadFails() async {
        for _ in 0..<2 {
            let field = FakeField(
                texts: [Self.before, Self.after, nil],
                events: [.valueChanged, .focusLeft],
            )
            await observe(field: field)
        }
        #expect(words.words.map(\.text) == ["Supabase"])
    }

    @Test
    func learnsFromTheLastTextThatStillHeldTheInsertionWhenTheFieldIsClearedOnSend() async {
        for _ in 0..<2 {
            let field = FakeField(
                texts: [Self.before, Self.after, "", ""],
                events: [.valueChanged, .valueChanged, .focusLeft],
            )
            await observe(field: field)
        }
        #expect(words.words.map(\.text) == ["Supabase"])
    }

    @Test
    func readsTheFinalTextWhenTheWatchTimesOut() async {
        for _ in 0..<2 {
            let field = FakeField(texts: [Self.before, Self.after], events: [])
            await observe(field: field, clock: ImmediateClock<Duration>())
        }
        #expect(words.words.map(\.text) == ["Supabase"])
    }

    @Test
    func endsWhenTheFieldStopsEmittingEvents() async {
        let field = FakeField(texts: [Self.before, Self.after], events: [])
        await field.close()
        await observe(field: field)
        #expect(words.words.isEmpty)
    }

    @Test
    func neverWatchesASecureField() async {
        let watcher = FakeFieldWatcher(field: FakeField(texts: [Self.before], events: []))
        await makeLearner(watcher: watcher)
            .observe(
                inserted: Self.inserted,
                into: Self.target,
                focus: focus(isSecure: true),
            )
        #expect(watcher.watchedPIDList.isEmpty)
    }

    @Test
    func watchesTheTargetApp() async {
        let watcher = FakeFieldWatcher(field: nil)
        await makeLearner(watcher: watcher)
            .observe(
                inserted: Self.inserted,
                into: Self.target,
                focus: focus(isSecure: false),
            )
        #expect(watcher.watchedPIDList == [7])
    }

    @Test
    func ignoresAFieldWhoseTextDoesNotContainTheInsert() async {
        let field = FakeField(texts: ["something else", Self.after], events: [.focusLeft])
        await observe(field: field)
        #expect(field.isClosed)
        #expect(words.words.isEmpty)
    }

    @Test
    func ignoresAFieldWithUnreadableText() async {
        let field = FakeField(texts: [nil], events: [.focusLeft])
        await observe(field: field)
        #expect(field.isClosed)
    }

    @Test
    func ignoresEditsThatAreNotRespellings() async {
        let field = FakeField(
            texts: [Self.before, "Notes: I use dogs daily"],
            events: [.focusLeft],
        )
        await observe(field: field)
        await observe(
            field: FakeField(
                texts: [Self.before, "Notes: I use dogs daily"],
                events: [.focusLeft],
            )
        )
        #expect(words.words.isEmpty)
    }

    @Test
    func survivesAStoreFailure() async {
        words.failure = .writeFailed(code: 1)
        await observe(field: FakeField(texts: [Self.before, Self.after], events: [.focusLeft]))
        #expect(words.words.isEmpty)
    }

    @Test
    func aCancelledObservationRecordsNothing() async {
        for _ in 0..<2 {
            let field = FakeField(texts: [Self.before, Self.after], events: [.focusLeft])
            let learner = makeLearner(watcher: FakeFieldWatcher(field: field))
            let task = Task {
                await learner.observe(
                    inserted: Self.inserted,
                    into: Self.target,
                    focus: focus(isSecure: false),
                )
            }
            task.cancel()
            await task.value
        }
        #expect(words.words.isEmpty)
    }

    private func observe(field: FakeField, clock: any Clock<Duration> = ManualClock()) async {
        await makeLearner(watcher: FakeFieldWatcher(field: field), clock: clock)
            .observe(
                inserted: Self.inserted,
                into: Self.target,
                focus: focus(isSecure: false),
            )
    }

    private func makeLearner(
        watcher: FakeFieldWatcher,
        clock: any Clock<Duration> = ManualClock(),
    ) -> CorrectionLearner {
        CorrectionLearner(words: words, watcher: watcher, clock: clock)
    }

    private func focus(isSecure: Bool) -> FocusSnapshot {
        FocusSnapshot(
            target: Self.target,
            fieldKind: .multiLine,
            fieldID: 1,
            isSecure: isSecure,
            isComposing: false,
            textBefore: nil,
        )
    }
}
