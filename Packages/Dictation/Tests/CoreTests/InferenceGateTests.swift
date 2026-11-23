@testable import Core
import Synchronization
import Testing

internal struct InferenceGateTests {
    private typealias Job = @Sendable () async throws(SpeechError) -> Void

    private let gate = InferenceGate()
    private let recorder = Recorder()

    @Test
    func runsWaitersInArrivalOrder() async {
        let holder = await holdGate()
        var tasks: [Task<SpeechError?, Never>] = []
        for label in 1...5 {
            tasks.append(enqueue(label))
            await waitUntilWaiting(label)
        }
        holder.release()
        for task in tasks {
            _ = await task.value
        }
        _ = await holder.task.value
        #expect(recorder.values == [1, 2, 3, 4, 5])
    }

    @Test
    func neverRunsTwoJobsAtOnce() async {
        let counter = ConcurrencyCounter()
        var tasks: [Task<SpeechError?, Never>] = []
        for _ in 0..<20 {
            tasks.append(
                launch {
                    counter.enter()
                    await Task.yield()
                    counter.leave()
                }
            )
        }
        for task in tasks {
            _ = await task.value
        }
        #expect(counter.peak == 1)
        #expect(counter.finished == 20)
    }

    @Test
    func cancelledWaiterLeavesQueueWithoutBlockingOthers() async {
        let holder = await holdGate()
        let first = enqueue(1)
        await waitUntilWaiting(1)
        let cancelled = enqueue(2)
        await waitUntilWaiting(2)
        let last = enqueue(3)
        await waitUntilWaiting(3)

        cancelled.cancel()
        let cancelledError = await cancelled.value
        #expect(gate.waiterCount == 2)

        holder.release()
        _ = await first.value
        _ = await last.value
        _ = await holder.task.value
        #expect(cancelledError == .cancelled)
        #expect(recorder.values == [1, 3])
    }

    @Test
    func alreadyCancelledCallerThrowsWithoutRunningAndLeavesGateFree() async {
        let recorder = recorder
        let task = launch {
            while !Task.isCancelled { await Task.yield() }
            recorder.append(1)
        }
        task.cancel()
        let error = await task.value
        let next = await enqueue(2).value
        #expect(error == .cancelled)
        #expect(next == nil)
        #expect(recorder.values == [2])
    }

    @Test
    func rethrowsWorkErrorAndReleasesGate() async {
        let gate = gate
        let error = await Task { () async -> CleanupError? in
            do throws(CleanupError) {
                try await gate.run { () async throws(CleanupError) in throw .timedOut }
                return nil
            } catch {
                return error
            }
        }
        .value
        let next = await enqueue(1).value
        #expect(error == .timedOut)
        #expect(next == nil)
    }

    private func launch(
        _ work: @escaping Job
    ) -> Task<SpeechError?, Never> {
        let gate = gate
        return Task {
            do throws(SpeechError) {
                try await gate.run(work)
                return nil
            } catch {
                return error
            }
        }
    }

    private func enqueue(_ label: Int) -> Task<SpeechError?, Never> {
        let recorder = recorder
        return launch { recorder.append(label) }
    }

    private func waitUntilWaiting(_ count: Int) async {
        while gate.waiterCount < count {
            await Task.yield()
        }
    }

    private func holdGate() async -> (
        task: Task<SpeechError?, Never>, release: @Sendable () -> Void
    ) {
        let started = AsyncStream.makeStream(of: Void.self)
        let released = AsyncStream.makeStream(of: Void.self)
        let task = launch {
            started.continuation.yield()
            for await _ in released.stream {}
        }
        for await _ in started.stream { break }
        return (task, { released.continuation.finish() })
    }
}
