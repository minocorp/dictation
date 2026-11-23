import Clocks
import Core
import CoreTesting
import Foundation
@testable import Session
import Testing

@MainActor
internal struct SessionRunnerTests {
    private let harness = RunnerHarness()

    @Test
    func holdThenReleaseInsertsTheCleanedText() async throws {
        await harness.dictate("Hello world.")
        let call = try #require(harness.inserter.calls.first)
        #expect(call.text == "Hello world.")
        #expect(call.target == Fixture.app)
        #expect(call.focus == Fixture.focus)
        await harness.runner.waitForWork()
        let saved = try #require(harness.history.items.first)
        #expect(saved.status == .inserted)
        #expect(saved.finalText == "Hello world.")
        #expect(saved.rawText == "hello world")
        #expect(saved.audioURL == Fixture.audioURL)
        #expect(harness.sounds.played == [.start, .finish])
        #expect(harness.keys.policies.map(\.swallowsEscape) == [true, false])
        #expect(harness.runner.state.lastResult?.item.finalText == "Hello world.")
    }

    @Test
    func startingCaptureWarmsTheSpeechEngineOncePerDictation() async {
        #expect(harness.speech.preheatCount == 0)
        await harness.holdUntilThresholdPasses()
        await harness.until { harness.speech.preheatCount == 1 }
        harness.runner.perform(.released)
        harness.voice.finish()
        await harness.until { harness.runner.state.isIdle }
        #expect(harness.speech.preheatCount == 1)
    }

    @Test
    func recognitionRunsPerSegmentWithTheDictionaryAsContext() async {
        await harness.holdUntilThresholdPasses()
        await harness.emitSegment(index: 0)
        await harness.emitSegment(index: 1)
        let calls = harness.speech.transcribeCalls
        #expect(calls.map(\.segment.index) == [0, 1])
        #expect(calls.map(\.context) == ["", ""])
        #expect(calls.allSatisfy { $0.languages == Fixture.languages })
    }

    @Test
    func handsFreeEndsAfterTheSilenceLimitAndCountsDown() async {
        let harness = RunnerHarness(silenceLimit: .seconds30)
        harness.runner.perform(.pressBegan)
        harness.runner.perform(.released)
        harness.runner.perform(.handsFreeBegan)
        for second in 1...20 {
            await harness.clock.advance(by: .seconds(1))
            await harness.until {
                harness.runner.state.hud
                    == .handsFree(
                        elapsed: .seconds(second),
                        countdown: second >= 20 ? .seconds(10) : nil,
                    )
            }
        }
        for _ in 21...30 {
            await harness.clock.advance(by: .seconds(1))
            await harness.until { harness.audio.stopCount > 0 || harness.runner.state.isLive }
        }
        await harness.until { harness.audio.stopCount == 1 }
        #expect(!harness.runner.state.isLive)
        harness.voice.finish()
        await harness.until { harness.runner.state.hud == .noSpeech }
        await harness.clock.advance(by: .milliseconds(1_500))
        await harness.until { harness.runner.state.hud == .hidden }
        #expect(harness.inserter.calls.isEmpty)
    }

    @Test
    func cancelKeepsTheAudioAndRestoreInsertsIt() async throws {
        await harness.holdUntilThresholdPasses()
        harness.runner.perform(.cancel)
        await harness.until { harness.runner.state.lastResult != nil }
        #expect(harness.runner.state.hud == .canceled)
        await harness.runner.waitForWork()
        let canceled = try #require(harness.history.items.first)
        #expect(canceled.status == .canceled)
        #expect(canceled.audioURL == Fixture.audioURL)
        #expect(harness.sounds.played == [.start, .cancel])
        harness.runner.perform(.restore)
        await harness.until { harness.inserter.calls.count == 1 }
        await harness.until { harness.runner.state.isIdle }
        await harness.runner.waitForWork()
        #expect(harness.files.requests == [Fixture.audioURL])
        #expect(harness.inserter.calls.first?.target == Fixture.app)
        let restored = try #require(harness.history.items.first)
        #expect(harness.history.items.count == 1)
        #expect(restored.id == canceled.id)
        #expect(restored.status == .inserted)
        #expect(restored.finalText == "Hello world.")
    }

    @Test
    func pasteLastWaitsBehindTheQueue() async {
        await harness.dictate("First.")
        harness.cleanup.cleanResult = .success("Second.")
        await harness.holdUntilThresholdPasses()
        await harness.emitSegment()
        harness.runner.perform(.released)
        harness.runner.perform(.pasteLast)
        await harness.runner.waitForWork()
        #expect(harness.inserter.calls.map(\.text) == ["First."])
        harness.voice.finish()
        await harness.until { harness.inserter.calls.count == 3 }
        #expect(harness.inserter.calls.map(\.text) == ["First.", "Second.", "Second."])
        await harness.until { harness.runner.state.isIdle }
    }

    @Test
    func staleResultsForAnEndedDictationAreDropped() async {
        await harness.holdUntilThresholdPasses()
        await harness.emitSegment()
        guard let id = harness.currentID else { return }
        harness.runner.perform(.cancel)
        await harness.until { harness.runner.state.lastResult != nil }
        await harness.runner.waitForWork()
        let stale: [ResultEvent] = [
            .transcribed(index: 0, result: .success("late")),
            .cleaned(index: 0, result: .success("Late.")),
            .inserted(.inserted(.pasteShortcut)),
        ]
        for result in stale {
            harness.runner.send(.result(id, result))
            harness.runner.send(.result(DictationID(), result))
        }
        await harness.runner.waitForWork()
        #expect(harness.inserter.calls.isEmpty)
        #expect(harness.history.items.count == 1)
        #expect(harness.runner.state.lastResult?.item.status == .canceled)
        #expect(harness.runner.state.isIdle)
    }

    @Test
    func sleepDuringCaptureKeepsTheResultWithoutInserting() async throws {
        await harness.holdUntilThresholdPasses()
        await harness.emitSegment()
        harness.runner.systemWillSleep()
        harness.voice.finish()
        await harness.until { harness.runner.state.isIdle }
        await harness.runner.waitForWork()
        #expect(harness.inserter.calls.isEmpty)
        let kept = try #require(harness.history.items.first)
        #expect(kept.status == .recovered)
        #expect(kept.finalText == "Hello world.")
        #expect(harness.runner.state.lastResult?.item == kept)
    }

    @Test
    func copiedOutcomeWritesTheClipboard() async {
        harness.inserter.outcome = .copied(.targetLostFocus)
        await harness.dictate("Hello world.")
        await harness.runner.waitForWork()
        #expect(harness.clipboard.copied == ["Hello world."])
        #expect(harness.runner.state.hud == .copied)
        await harness.clock.advance(by: .seconds(3))
        await harness.until { harness.runner.state.hud == .hidden }
    }

    @Test
    func launchRecoversOrphanAudioWithoutInserting() async throws {
        let id = DictationID()
        let orphan = URL(fileURLWithPath: "/tmp/audio/\(id.stem).caf")
        harness.history.orphans = [orphan]
        await harness.runner.launch()
        await harness.until { harness.runner.state.isIdle && harness.files.requests == [orphan] }
        await harness.runner.waitForWork()
        let recovered = try #require(harness.history.items.first)
        #expect(recovered.id == id)
        #expect(recovered.status == .recovered)
        #expect(harness.inserter.calls.isEmpty)
    }
}
