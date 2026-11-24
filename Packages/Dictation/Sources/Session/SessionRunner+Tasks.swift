import Core
import Foundation

extension SessionRunner {
    @discardableResult
    func spawn(
        _ id: DictationID?,
        _ body: @escaping @MainActor () async -> Void,
    ) -> Task<
        Void, Never
    > {
        let token = UUID()
        let task = Task { [weak self] in
            await body()
            self?.tracked[token] = nil
        }
        tracked[token] = TrackedTask(id: id, task: task)
        return task
    }

    func spawnSerial(
        _ lane: WorkLane,
        _ body: @escaping @MainActor () async -> Void,
    ) {
        let previous = tails[lane]
        tails[lane] = spawn(nil) {
            await previous?.value
            await body()
        }
    }

    func cancelWork(_ id: DictationID) {
        for (token, entry) in tracked where entry.id == id {
            entry.task.cancel()
            tracked[token] = nil
        }
    }

    func startTimer(_ timer: SessionTimer, after duration: Duration) {
        timers[timer]?.task.cancel()
        nextTimerGeneration += 1
        let generation = nextTimerGeneration
        let clock = environment.clock
        let task = Task { [weak self] in
            guard await clock.sleepUnlessCancelled(for: duration) else { return }
            guard !Task.isCancelled else { return }
            self?.timerFired(timer, generation: generation)
        }
        timers[timer] = ScheduledTimer(generation: generation, task: task)
    }

    func cancelTimer(_ timer: SessionTimer) {
        timers[timer]?.task.cancel()
        timers[timer] = nil
    }

    private func timerFired(_ timer: SessionTimer, generation: Int) {
        guard timers[timer]?.generation == generation else { return }
        timers[timer] = nil
        send(.timer(timer))
    }
}
