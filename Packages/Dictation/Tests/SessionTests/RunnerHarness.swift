import Clocks
import Core
import CoreTesting
@testable import Session
import Testing

@MainActor
internal final class RunnerHarness {
    let keys = FakeKeySource()
    let audio = FakeAudioSource()
    let voice = FakeVoiceActivity()
    let files = FakeAudioFileSegmenter()
    let speech = FakeSpeechEngine()
    let cleanup = FakeCleanupPipeline()
    let focus = FakeFocusReader()
    let inserter = FakeTextInserter()
    let clipboard = FakeClipboardWriter()
    let history = FakeHistoryStore()
    let words = FakeWordStore()
    let sounds = FakeSoundPlayer()
    let clock = Clocks.TestClock<Duration>()
    let runner: SessionRunner

    init(silenceLimit: HandsFreeSilenceLimit = .minutes2) {
        var configured = Fixture.preferences
        configured.handsFreeSilenceLimit = silenceLimit
        let preferences = configured
        let speechEngine = speech
        runner = SessionRunner(
            inputs: SessionInputs(keys: keys, audio: audio, voice: voice, files: files),
            engines: SessionEngines(
                speech: { speechEngine },
                preheat: { await speechEngine.preheat() },
                cleanup: cleanup,
                words: words,
                learning: IgnoringLearningObserver(),
            ),
            outputs: SessionOutputs(
                focus: focus,
                inserter: inserter,
                clipboard: clipboard,
                sounds: sounds,
            ),
            environment: SessionEnvironment(
                history: history,
                preferences: { preferences },
                clock: clock,
            ),
        )
        runner.permissionChanged(Fixture.granted)
        focus.snapshotResult = Fixture.focus
        audio.stopURL = Fixture.audioURL
        speech.transcribeResult = .success("hello world")
        cleanup.cleanResult = .success("Hello world.")
    }

    var currentID: DictationID? { audio.startCalls.last?.id }

    func until(_ condition: () -> Bool) async {
        for _ in 0..<10_000 {
            if condition() { return }
            await Task.yield()
        }
        Issue.record("condition was not reached")
    }

    func holdUntilThresholdPasses() async {
        runner.perform(.pressBegan)
        await clock.advance(by: .milliseconds(300))
    }

    func emitSegment(index: Int = 0) async {
        guard let id = currentID else { return }
        let before = speech.transcribeCalls.count
        voice.emit(Fixture.segment(index, id))
        await until { self.speech.transcribeCalls.count > before }
    }

    func dictate(_ cleaned: String) async {
        cleanup.cleanResult = .success(cleaned)
        let before = inserter.calls.count
        await holdUntilThresholdPasses()
        await emitSegment()
        runner.perform(.released)
        voice.finish()
        await until { self.inserter.calls.count > before }
        await until { self.runner.state.isIdle }
    }
}

extension SessionRunner {
    func waitForWork() async {
        while let entry = tracked.values.first {
            await entry.task.value
        }
    }
}
