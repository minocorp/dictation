public import Core
import Foundation
import FoundationModels
import Synchronization

public final class FoundationModelsCleanupEngine: CleanupEngine {
    private let model: SystemLanguageModel
    private let gate: InferenceGate
    private let builder: PromptBuilder
    private let parser = OutputParser()
    private let instructionTokens = Mutex<[String: Int]>([:])

    public init(gate: InferenceGate, builder: PromptBuilder = PromptBuilder()) {
        model = SystemLanguageModel(
            useCase: .general,
            guardrails: .permissiveContentTransformations,
        )
        self.gate = gate
        self.builder = builder
    }

    public func prepare() async throws(CleanupError) {
        try ensureAvailable()
        let warmup = CleanupRequest(
            text: "",
            dictionary: [],
            contextBefore: "",
            languages: [],
        )
        let prompt = builder.cleanupPrompt(for: warmup, profile: .foundationModels)
        LanguageModelSession(model: model, instructions: prompt.instructionsText).prewarm()
    }

    public func clean(_ request: CleanupRequest) async throws(CleanupError) -> String {
        try ensureAvailable()
        try ensureSupportsLanguage(of: request.languages)
        let prompt = builder.cleanupPrompt(for: request, profile: .foundationModels)
        return try await gate.run { () async throws(CleanupError) -> String in
            try await generate(prompt, tag: .cleaned, transcript: request.text)
        }
    }

    public func edit(_ request: EditRequest) async throws(CleanupError) -> String {
        try ensureAvailable()
        let prompt = builder.editPrompt(for: request)
        return try await gate.run { () async throws(CleanupError) -> String in
            try await generate(prompt, tag: .edited, transcript: request.selection)
        }
    }

    public func unload() async {}

    private func ensureAvailable() throws(CleanupError) {
        switch model.availability {
        case .available: return
        case .unavailable: throw .modelUnavailable
        }
    }

    private func ensureSupportsLanguage(of languages: [Locale]) throws(CleanupError) {
        guard languages.isEmpty || languages.contains(where: { model.supportsLocale($0) }) else {
            throw .rejected
        }
    }

    private func generate(
        _ prompt: CleanupPrompt,
        tag: OutputTag,
        transcript: String,
    ) async throws(CleanupError) -> String {
        try await ensureFits(prompt, transcript: transcript)
        let options = GenerationOptions(
            samplingMode: prompt.temperature == 0 ? .greedy : nil,
            temperature: prompt.temperature == 0 ? nil : prompt.temperature,
            maximumResponseTokens: prompt.maximumTokens,
        )
        let session = LanguageModelSession(model: model, instructions: prompt.instructionsText)
        let raw: String
        do {
            raw = try await session.respond(to: prompt.userText, options: options).content
        } catch {
            throw FoundationModelsErrorMap.cleanupError(from: error)
        }
        let reachedLimit = try await hasReachedLimit(raw, tag: tag, limit: prompt.maximumTokens)
        guard let text = parser.parse(raw, tag: tag, reachedTokenLimit: reachedLimit) else {
            throw .rejected
        }
        return text
    }

    private func hasReachedLimit(
        _ raw: String,
        tag: OutputTag,
        limit: Int,
    ) async throws(CleanupError) -> Bool {
        guard !raw.contains(tag.closing) else { return false }
        return try await tokenCount(of: raw) >= limit
    }

    private func ensureFits(
        _ prompt: CleanupPrompt,
        transcript: String,
    ) async throws(CleanupError) {
        let userTokens = try await tokenCount(of: prompt.userText)
        if userTokens > PromptBuilder.foundationModelsTranscriptTokenLimit {
            let transcriptTokens = try await tokenCount(of: transcript)
            guard transcriptTokens <= PromptBuilder.foundationModelsTranscriptTokenLimit else {
                throw .rejected
            }
        }
        let promptTokens = try await instructionTokenCount(of: prompt.instructionsText) + userTokens
        guard promptTokens + prompt.maximumTokens <= model.contextSize else { throw .rejected }
    }

    private func instructionTokenCount(of text: String) async throws(CleanupError) -> Int {
        if let cached = instructionTokens.withLock({ $0[text] }) { return cached }
        let count = try await tokenCount(of: text)
        instructionTokens.withLock { $0[text] = count }
        return count
    }

    private func tokenCount(of text: String) async throws(CleanupError) -> Int {
        guard #available(macOS 26.4, *) else {
            return ApproximateTokenCounter().tokenCount(of: text)
        }
        do {
            return try await model.tokenCount(for: text)
        } catch {
            throw FoundationModelsErrorMap.cleanupError(from: error)
        }
    }
}
