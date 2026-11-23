import Core
import CoreTesting
import Foundation
@testable import ModelCatalog
import Testing

internal struct EngineRegistryTests {
    private let directory = URL(filePath: "/tmp/model")

    @Test
    func buildsSpeechEngineForRegisteredFamily() throws {
        let registry = EngineRegistry()
        let engine = FakeSpeechEngine()
        registry.registerSpeech(kind: "test") { _, _ in engine }
        let made = try registry.makeSpeechEngine(
            for: ManifestFixtures.entry(),
            directory: directory,
        )
        #expect((made as? FakeSpeechEngine) === engine)
    }

    @Test
    func buildsCleanupEngineForRegisteredFamily() throws {
        let registry = EngineRegistry()
        let engine = FakeCleanupEngine()
        registry.registerCleanup(kind: "test") { _, _ in engine }
        let entry = ManifestFixtures.entry(stage: .cleanup)
        let made = try registry.makeCleanupEngine(for: entry, directory: directory)
        #expect((made as? FakeCleanupEngine) === engine)
    }

    @Test
    func factoryReceivesEntryAndDirectory() throws {
        let registry = EngineRegistry()
        let received = ReceivedArguments()
        registry.registerSpeech(kind: "test") { entry, url in
            received.set(id: entry.id, directory: url)
            return FakeSpeechEngine()
        }
        _ = try registry.makeSpeechEngine(for: ManifestFixtures.entry(), directory: directory)
        #expect(received.value == ReceivedArguments.Value(id: "test-model", directory: directory))
    }

    @Test
    func unregisteredKindIsUnknown() {
        let registry = EngineRegistry()
        #expect(throws: ModelError.unknownModel) {
            try registry.makeSpeechEngine(for: ManifestFixtures.entry(), directory: directory)
        }
    }

    @Test
    func stageMismatchIsUnknown() {
        let registry = EngineRegistry()
        registry.registerSpeech(kind: "test") { _, _ in FakeSpeechEngine() }
        let cleanupEntry = ManifestFixtures.entry(stage: .cleanup)
        #expect(throws: ModelError.unknownModel) {
            try registry.makeCleanupEngine(for: cleanupEntry, directory: directory)
        }
        #expect(throws: ModelError.unknownModel) {
            try registry.makeSpeechEngine(for: cleanupEntry, directory: directory)
        }
    }
}
