public import Core

public struct SessionEngines: Sendable {
    let speech: @Sendable () async -> any SpeechEngine
    let preheat: @Sendable () async -> Void
    let cleanup: any CleanupPipeline
    let words: any WordStore
    let learning: any LearningObserver

    public init(
        speech: @escaping @Sendable () async -> any SpeechEngine,
        preheat: @escaping @Sendable () async -> Void,
        cleanup: any CleanupPipeline,
        words: any WordStore,
        learning: any LearningObserver,
    ) {
        self.speech = speech
        self.preheat = preheat
        self.cleanup = cleanup
        self.words = words
        self.learning = learning
    }
}
