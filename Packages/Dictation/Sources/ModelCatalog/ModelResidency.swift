public import Core

public actor ModelResidency {
    private struct Resident {
        let unload: @Sendable () async -> Void
        let generation: Int
        var idleTimer: Task<Void, Never>?
    }

    private static let idleLimit = Duration.seconds(600)
    private static let idleUnloadBelowGB = 16

    private let gate: InferenceGate
    private let ramGB: Int
    private let clock: any Clock<Duration>
    private var residents: [String: Resident] = [:]
    private var nextGeneration = 0

    public init(gate: InferenceGate, ramGB: Int, clock: any Clock<Duration>) {
        self.gate = gate
        self.ramGB = ramGB
        self.clock = clock
    }

    public func isResident(_ id: String) -> Bool {
        residents[id] != nil
    }

    public func didLoad(_ engine: any SpeechEngine, id: String) {
        track(id: id) { await engine.unload() }
    }

    public func didLoad(_ engine: any CleanupEngine, id: String) {
        track(id: id) { await engine.unload() }
    }

    public func didUse(id: String) {
        guard let resident = residents[id] else { return }
        track(id: id, unload: resident.unload)
    }

    public func memoryPressure() async {
        let all = residents
        residents = [:]
        for resident in all.values {
            resident.idleTimer?.cancel()
        }
        for (id, resident) in all {
            await unload(id: id, resident: resident)
        }
    }

    private func track(id: String, unload: @escaping @Sendable () async -> Void) {
        residents[id]?.idleTimer?.cancel()
        nextGeneration += 1
        let generation = nextGeneration
        residents[id] = Resident(
            unload: unload,
            generation: generation,
            idleTimer: idleTimer(id: id, generation: generation),
        )
    }

    private func idleTimer(id: String, generation: Int) -> Task<Void, Never>? {
        guard ramGB < Self.idleUnloadBelowGB else { return nil }
        let clock = clock
        return Task { [weak self] in
            guard await clock.sleepUnlessCancelled(for: Self.idleLimit) else { return }
            await self?.expire(id: id, generation: generation)
        }
    }

    private func expire(id: String, generation: Int) async {
        guard let resident = residents[id], resident.generation == generation else { return }
        residents[id] = nil
        await unload(id: id, resident: resident)
    }

    private func unload(id: String, resident: Resident) async {
        do {
            try await gate.run { () async throws(ModelError) in await resident.unload() }
        } catch {
            if residents[id] == nil { track(id: id, unload: resident.unload) }
        }
    }
}
