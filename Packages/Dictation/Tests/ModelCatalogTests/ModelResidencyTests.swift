import Clocks
import Core
import CoreTesting
@testable import ModelCatalog
import Testing

internal struct ModelResidencyTests {
    private let clock = CoreTesting.TestClock()
    private let gate = InferenceGate()

    private func makeResidency(ramGB: Int) -> ModelResidency {
        ModelResidency(gate: gate, ramGB: ramGB, clock: clock)
    }

    private func waitUntilGone(_ id: String, in residency: ModelResidency) async {
        while await residency.isResident(id) { await Task.yield() }
    }

    @Test
    func idleEngineUnloadsAfterTenMinutesUnder16GB() async {
        let residency = makeResidency(ramGB: 8)
        let engine = FakeSpeechEngine()
        await residency.didLoad(engine, id: "asr")
        await clock.advance(by: .seconds(599))
        #expect(engine.unloadCount == 0)
        await clock.advance(by: .seconds(1))
        await waitUntilGone("asr", in: residency)
        #expect(engine.unloadCount == 1)
    }

    @Test
    func engineStaysLoadedWhenIdleOn16GBOrMore() async {
        let residency = makeResidency(ramGB: 16)
        let engine = FakeSpeechEngine()
        await residency.didLoad(engine, id: "asr")
        await clock.advance(by: .seconds(3_600))
        #expect(await residency.isResident("asr"))
        #expect(engine.unloadCount == 0)
    }

    @Test
    func useRestartsTheIdleTimer() async {
        let residency = makeResidency(ramGB: 8)
        let engine = FakeCleanupEngine()
        await residency.didLoad(engine, id: "cleanup")
        await clock.advance(by: .seconds(540))
        await residency.didUse(id: "cleanup")
        await clock.advance(by: .seconds(540))
        #expect(await residency.isResident("cleanup"))
        await clock.advance(by: .seconds(60))
        await waitUntilGone("cleanup", in: residency)
        #expect(engine.unloadCount == 1)
    }

    @Test
    func memoryPressureUnloadsEveryEngineRegardlessOfRAM() async {
        let residency = makeResidency(ramGB: 64)
        let speech = FakeSpeechEngine()
        let cleanup = FakeCleanupEngine()
        await residency.didLoad(speech, id: "asr")
        await residency.didLoad(cleanup, id: "cleanup")
        await residency.memoryPressure()
        #expect(speech.unloadCount == 1)
        #expect(cleanup.unloadCount == 1)
        #expect(!(await residency.isResident("asr")))
    }

    @Test
    func unloadWaitsForTheInferenceGate() async {
        let residency = makeResidency(ramGB: 64)
        let engine = FakeSpeechEngine()
        await residency.didLoad(engine, id: "asr")
        let started = AsyncStream<Void>.makeStream()
        let release = AsyncStream<Void>.makeStream()
        let gate = gate
        let running = Task {
            await Self.occupy(gate, signal: started.continuation, until: release.stream)
        }
        for await _ in started.stream { break }
        let pressure = Task { await residency.memoryPressure() }
        for _ in 0..<20 { await Task.yield() }
        #expect(engine.unloadCount == 0)
        release.continuation.finish()
        await pressure.value
        await running.value
        #expect(engine.unloadCount == 1)
    }

    private static func occupy(
        _ gate: InferenceGate,
        signal: AsyncStream<Void>.Continuation,
        until release: AsyncStream<Void>,
    ) async {
        do {
            try await gate.run { () async throws(ModelError) in
                signal.yield()
                for await _ in release {}
            }
        } catch {
            return
        }
    }

    @Test
    func forgottenEngineIsNotUnloadedByTheTimer() async {
        let residency = makeResidency(ramGB: 8)
        let engine = FakeSpeechEngine()
        await residency.didLoad(engine, id: "asr")
        await residency.forget(id: "asr")
        await clock.advance(by: .seconds(1_200))
        #expect(engine.unloadCount == 0)
    }

    @Test
    func interruptedUnloadKeepsTheEngineTrackedWithAFreshIdleTimer() async {
        let residency = makeResidency(ramGB: 8)
        let engine = FakeSpeechEngine()
        await residency.didLoad(engine, id: "asr")
        let started = AsyncStream<Void>.makeStream()
        let release = AsyncStream<Void>.makeStream()
        let gate = gate
        let running = Task {
            await Self.occupy(gate, signal: started.continuation, until: release.stream)
        }
        for await _ in started.stream { break }
        let pressure = Task { await residency.memoryPressure() }
        for _ in 0..<20 { await Task.yield() }
        pressure.cancel()
        await pressure.value
        release.continuation.finish()
        await running.value
        #expect(await residency.isResident("asr"))
        await clock.advance(by: .seconds(600))
        await waitUntilGone("asr", in: residency)
        #expect(engine.unloadCount == 1)
    }

    @Test
    func interruptedUnloadDoesNotReplaceANewerRegistration() async {
        let residency = makeResidency(ramGB: 64)
        let old = FakeSpeechEngine()
        let replacement = FakeSpeechEngine()
        await residency.didLoad(old, id: "asr")
        let started = AsyncStream<Void>.makeStream()
        let release = AsyncStream<Void>.makeStream()
        let gate = gate
        let running = Task {
            await Self.occupy(gate, signal: started.continuation, until: release.stream)
        }
        for await _ in started.stream { break }
        let pressure = Task { await residency.memoryPressure() }
        for _ in 0..<20 { await Task.yield() }
        await residency.didLoad(replacement, id: "asr")
        pressure.cancel()
        await pressure.value
        release.continuation.finish()
        await running.value
        await residency.memoryPressure()
        #expect(replacement.unloadCount == 1)
        #expect(old.unloadCount == 0)
    }
}
