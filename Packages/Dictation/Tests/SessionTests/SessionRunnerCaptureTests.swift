import Clocks
import Core
import CoreTesting
import Foundation
@testable import Session
import Testing

@MainActor
internal struct SessionRunnerCaptureTests {
    private let harness = RunnerHarness()

    @Test
    func abandonRightAfterPressDeletesTheCapturedFile() async {
        harness.runner.perform(.pressBegan)
        harness.runner.perform(.abandon)
        await harness.until { harness.audio.discarded == [Fixture.audioURL] }
        #expect(harness.audio.stopCount == 1)
        await harness.runner.waitForWork()
        #expect(harness.history.items.isEmpty)
        #expect(harness.runner.state.isIdle)
    }

    @Test
    func tapWithoutSpeechDeletesTheCapturedFile() async {
        harness.runner.perform(.pressBegan)
        harness.runner.perform(.released)
        await harness.clock.advance(by: .milliseconds(400))
        await harness.until { harness.audio.stopCount == 1 }
        harness.voice.finish()
        await harness.until { harness.audio.discarded == [Fixture.audioURL] }
        await harness.runner.waitForWork()
        #expect(harness.history.items.isEmpty)
        #expect(harness.runner.state.hud == .hidden)
    }

    @Test
    func captureFailureKeepsTheAudioAsAFailedHistoryItem() async throws {
        await harness.holdUntilThresholdPasses()
        await harness.until {
            harness.runner.state.hud == .listening && harness.audio.stopCount == 0
        }
        harness.audio.emitFailure(.diskWriteFailed(code: 28))
        await harness.until { harness.audio.stopCount == 1 }
        harness.voice.finish()
        await harness.until { harness.runner.state.hud == .problem(.couldNotSave) }
        await harness.runner.waitForWork()
        let kept = try #require(harness.history.items.first)
        #expect(kept.status == .failed)
        #expect(kept.audioURL == Fixture.audioURL)
        #expect(harness.audio.discarded.isEmpty)
    }

    @Test
    func captureStartFailureShowsAProblemAndLeavesNoHistory() async {
        harness.audio.startResult = .failure(.noInputDevice)
        harness.runner.perform(.pressBegan)
        await harness.until { harness.runner.state.hud == .problem(.microphoneUnavailable) }
        await harness.runner.waitForWork()
        #expect(harness.history.items.isEmpty)
        #expect(harness.runner.state.isIdle)
    }

    @Test
    func unreadableOrphanIsKeptAsAFailedItem() async throws {
        let id = DictationID()
        let orphan = URL(fileURLWithPath: "/tmp/audio/\(id.stem).caf")
        harness.history.orphans = [orphan]
        harness.files.failure = .failed(code: 1)
        await harness.runner.launch()
        await harness.until { harness.runner.state.isIdle }
        await harness.runner.waitForWork()
        let kept = try #require(harness.history.items.first)
        #expect(kept.status == .failed)
        #expect(kept.audioURL == orphan)
        #expect(harness.audio.discarded.isEmpty)
    }

    @Test
    func releasingDuringTheSelectionReadStillFinishesTheEdit() async {
        harness.focus.selectionResult = .text("long text")
        harness.runner.perform(.editBegan)
        harness.runner.perform(.released)
        await harness.until { harness.audio.stopCount == 1 }
        #expect(harness.sounds.played.contains(.finish))
        harness.voice.finish()
        await harness.until { harness.runner.state.isIdle }
    }

    @Test
    func editStartsCapturingAtKeyDownAndDiscardsWhenTheSelectionIsTooLong() async {
        harness.focus.selectionResult = .tooLong
        harness.runner.perform(.editBegan)
        await harness.until { harness.audio.discarded == [Fixture.audioURL] }
        await harness.until { harness.runner.state.hud == .problem(.selectionTooLong) }
        #expect(harness.audio.startCalls.count == 1)
        await harness.runner.waitForWork()
        #expect(harness.history.items.isEmpty)
    }

    @Test
    func repostedNoticeRestartsItsExpiry() async {
        harness.runner.hotkeyFailed(.eventTapUnavailable)
        await harness.clock.advance(by: .seconds(5))
        harness.runner.hotkeyFailed(.eventTapUnavailable)
        await harness.clock.advance(by: .seconds(5))
        await harness.until { harness.runner.timers[.hudExpiry] != nil }
        #expect(harness.runner.state.hud == .problem(.accessibilityOff))
        await harness.clock.advance(by: .seconds(3))
        await harness.until { harness.runner.state.hud == .hidden }
    }
}
