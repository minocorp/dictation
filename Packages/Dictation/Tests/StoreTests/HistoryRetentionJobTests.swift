import Clocks
import Core
import CoreTesting
import Foundation
@testable import Store
import Testing

internal struct HistoryRetentionJobTests {
    private static let day: TimeInterval = 86_400
    private static let now = Date(timeIntervalSince1970: 100 * day)

    private let fixtures = HistoryFixtures()

    private func makeJob(
        retention: HistoryRetention,
        clock: CoreTesting.TestClock = CoreTesting.TestClock(),
    ) throws -> (GRDBHistoryStore, HistoryRetentionJob) {
        let store = GRDBHistoryStore(
            database: try fixtures.makeDatabase(),
            retention: { retention },
        )
        let job = HistoryRetentionJob(
            store: store,
            retention: { retention },
            clock: clock,
            now: { Self.now },
        )
        return (store, job)
    }

    private func age(days: Double) -> TimeInterval {
        Self.now.timeIntervalSince1970 - days * Self.day
    }

    @Test(arguments: [
        (HistoryRetention.thirtyDays, [29.0], [31.0]),
        (HistoryRetention.oneDay, [0.5], [1.5]),
        (HistoryRetention.off, [], [0.001]),
    ])
    func purgesRowsOlderThanRetention(
        retention: HistoryRetention,
        keptAges: [Double],
        droppedAges: [Double],
    ) async throws {
        let (store, job) = try makeJob(retention: retention)
        for days in keptAges + droppedAges {
            try await store.save(fixtures.item(date: age(days: days), raw: "age\(days)"))
        }
        try await job.runOnce()
        let remaining = try await store.search("", limit: 10).map(\.rawText).sorted()
        #expect(remaining == keptAges.map { "age\($0)" }.sorted())
    }

    @Test
    func unfinishedItemsKeepTheAudioWindowWithRetentionOff() async throws {
        let (store, job) = try makeJob(retention: .off)
        let recent = fixtures.item(date: age(days: 0.5), raw: "recent", status: .canceled)
        let old = fixtures.item(date: age(days: 1.5), raw: "old", status: .failed)
        try await store.save(recent)
        try await store.save(old)
        try await job.runOnce()
        #expect(try await store.search("", limit: 10).map(\.rawText) == ["recent"])
    }

    @Test
    func pendingItemsSurviveRetention() async throws {
        let (store, job) = try makeJob(retention: .oneDay)
        let pending = fixtures.item(date: age(days: 40), status: .pending)
        try await store.save(pending)
        try await job.runOnce()
        #expect(try await store.item(id: pending.id) == pending)
    }

    @Test
    func audioOlderThanOneDayIsDeletedButRowStays() async throws {
        let (store, job) = try makeJob(retention: .thirtyDays)
        let oldAudio = try fixtures.writeAudio(named: "old")
        let freshAudio = try fixtures.writeAudio(named: "fresh")
        let old = fixtures.item(date: age(days: 2), audioURL: oldAudio)
        let fresh = fixtures.item(date: age(days: 0.5), audioURL: freshAudio)
        try await store.save(old)
        try await store.save(fresh)
        try await job.runOnce()
        #expect(!FileManager.default.fileExists(atPath: oldAudio.path()))
        #expect(FileManager.default.fileExists(atPath: freshAudio.path()))
        #expect(try await store.item(id: old.id).audioURL == nil)
    }

    @Test
    func pendingAudioIsNeverExpired() async throws {
        let (store, job) = try makeJob(retention: .thirtyDays)
        let audio = try fixtures.writeAudio(named: "waiting")
        try await store.save(fixtures.item(date: age(days: 5), audioURL: audio, status: .pending))
        try await job.runOnce()
        #expect(FileManager.default.fileExists(atPath: audio.path()))
    }

    @Test
    func purgedRowsTakeTheirAudioWithThem() async throws {
        let (store, job) = try makeJob(retention: .oneDay)
        let audio = try fixtures.writeAudio(named: "gone")
        try await store.save(fixtures.item(date: age(days: 3), audioURL: audio))
        try await job.runOnce()
        #expect(!FileManager.default.fileExists(atPath: audio.path()))
        #expect(try await store.orphanAudio().isEmpty)
    }

    @Test
    func scheduleRunsAtStartAndEveryDay() async throws {
        let clock = CoreTesting.TestClock()
        let (store, job) = try makeJob(retention: .oneDay, clock: clock)
        let stale = fixtures.item(date: age(days: 3), raw: "stale")
        try await store.save(stale)
        await job.start()
        while try await store.search("stale", limit: 1).count == 1 { await Task.yield() }
        try await store.save(fixtures.item(date: age(days: 3), raw: "stale-again"))
        await clock.advance(by: .seconds(86_400))
        while try await store.search("stale", limit: 1).count == 1 { await Task.yield() }
        await job.stop()
        #expect(try await store.search("", limit: 10).isEmpty)
    }
}
