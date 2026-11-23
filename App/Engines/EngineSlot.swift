import Core
import Foundation
import ModelCatalog
import Synchronization

internal final class EngineSlot<Engine: Sendable>: Sendable {
    struct Behavior: Sendable {
        let name: String
        let fallback: Engine
        let make: @Sendable (ModelEntry, URL) throws -> Engine
        let prepare: @Sendable (Engine) async throws -> Void
        let didLoad: @Sendable (Engine, String) async -> Void
    }

    private struct Flights {
        var loads: [String: Task<Engine?, Never>] = [:]
        var reloads: [String: Task<Bool, Never>] = [:]
    }

    private let library: ManifestModelLibrary
    private let residency: ModelResidency
    private let behavior: Behavior
    private let flights = Mutex(Flights())

    init(library: ManifestModelLibrary, residency: ModelResidency, behavior: Behavior) {
        self.library = library
        self.residency = residency
        self.behavior = behavior
    }

    func resolve(_ entry: ModelEntry) async -> Engine {
        guard entry.isDownloadable, await library.state(of: entry) == .ready else {
            return behavior.fallback
        }
        let load = loadFlight(for: entry)
        guard let engine = await load.value else {
            flights.withLock { flights in
                if flights.loads[entry.id] == load { flights.loads[entry.id] = nil }
            }
            return behavior.fallback
        }
        return await keepResident(engine, id: entry.id)
    }

    private func loadFlight(for entry: ModelEntry) -> Task<Engine?, Never> {
        flights.withLock { flights in
            if let existing = flights.loads[entry.id] { return existing }
            let created = Task { await self.load(entry) }
            flights.loads[entry.id] = created
            return created
        }
    }

    private func load(_ entry: ModelEntry) async -> Engine? {
        let started = ContinuousClock.now
        do {
            let directory = try await library.verifiedDirectory(of: entry)
            let engine = try behavior.make(entry, directory)
            try await behavior.prepare(engine)
            await behavior.didLoad(engine, entry.id)
            Self.logLoad(behavior.name, since: started)
            return engine
        } catch {
            AppLog.failure("load \(behavior.name) model", error)
            return nil
        }
    }

    private func keepResident(_ engine: Engine, id: String) async -> Engine {
        guard await residency.isResident(id) else {
            let reload = reloadFlight(engine, id: id)
            return await reload.value ? engine : behavior.fallback
        }
        await residency.didUse(id: id)
        return engine
    }

    private func reloadFlight(_ engine: Engine, id: String) -> Task<Bool, Never> {
        flights.withLock { flights in
            if let existing = flights.reloads[id] { return existing }
            let created = Task { await self.reload(engine, id: id) }
            flights.reloads[id] = created
            return created
        }
    }

    private func reload(_ engine: Engine, id: String) async -> Bool {
        defer { flights.withLock { $0.reloads[id] = nil } }
        do {
            try await behavior.prepare(engine)
            await behavior.didLoad(engine, id)
            return true
        } catch {
            AppLog.failure("reload \(behavior.name) model", error)
            return false
        }
    }

    private static func logLoad(_ name: String, since started: ContinuousClock.Instant) {
        TimingLog.mark(
            "\(name)-model-prepared",
            "duration-ms=\(started.duration(to: ContinuousClock.now).milliseconds) during-dictation=\(TimingLog.isDictationInFlight)",
        )
    }
}
