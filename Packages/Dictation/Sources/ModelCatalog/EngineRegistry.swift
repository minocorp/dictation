public import Core
public import Foundation
import Synchronization

public final class EngineRegistry: Sendable {
    public typealias SpeechFactory = @Sendable (ModelEntry, URL) -> any SpeechEngine
    public typealias CleanupFactory = @Sendable (ModelEntry, URL) -> any CleanupEngine

    private struct Factories {
        var speech: [String: SpeechFactory] = [:]
        var cleanup: [String: CleanupFactory] = [:]
    }

    private let factories = Mutex(Factories())

    public init() {}

    public func registerSpeech(kind: String, factory: @escaping SpeechFactory) {
        factories.withLock { $0.speech[kind] = factory }
    }

    public func registerCleanup(kind: String, factory: @escaping CleanupFactory) {
        factories.withLock { $0.cleanup[kind] = factory }
    }

    public func makeSpeechEngine(
        for entry: ModelEntry,
        directory: URL,
    ) throws(ModelError) -> any SpeechEngine {
        guard entry.stage == .speech, let factory = factories.withLock({ $0.speech[entry.family] })
        else { throw .unknownModel }
        return factory(entry, directory)
    }

    public func makeCleanupEngine(
        for entry: ModelEntry,
        directory: URL,
    ) throws(ModelError) -> any CleanupEngine {
        guard entry.stage == .cleanup,
            let factory = factories.withLock({ $0.cleanup[entry.family] })
        else { throw .unknownModel }
        return factory(entry, directory)
    }
}
