import Cleanup
import Core
import Foundation
import MLX
import MLXLMCommon
import MLXMemory
import TokenizerBridge

internal actor QwenCleanupRuntime {
    private let builder: PromptBuilder
    private let memory = IdleCacheTrimmer()
    private var context: ModelContext?
    private var prefixes: [OutputTag: PrefixCache] = [:]

    init(builder: PromptBuilder) {
        self.builder = builder
    }

    func load(from directory: URL) async throws(CleanupError) {
        guard context == nil else { return }
        if Task.isCancelled { throw .cancelled }
        memory.limitCache()
        do {
            context = try await loadModel(
                from: directory,
                using: makeHuggingFaceTokenizerLoader(),
            )
        } catch {
            throw Task.isCancelled ? .cancelled : .modelUnavailable
        }
    }

    func prefill(_ tag: OutputTag) throws(CleanupError) {
        guard let context else { throw .modelUnavailable }
        guard prefixes[tag] == nil else { return }
        memory.begin()
        defer { memory.end() }
        prefixes[tag] = try makePrefixCache(tag: tag, context: context)
    }

    func warmUp(_ tag: OutputTag) throws(CleanupError) {
        let probe =
            switch tag {
            case .cleaned: PrefixProbes.cleanup(using: builder).first
            case .edited: PrefixProbes.edit(using: builder).first
            }
        guard let probe else { return }
        _ = try generate(probe, tag: tag)
    }

    func generate(_ prompt: CleanupPrompt, tag: OutputTag) throws(CleanupError) -> GeneratedText {
        guard let context else { throw .modelUnavailable }
        memory.begin()
        defer { memory.end() }
        try prefill(tag)
        let tokens = try promptTokens(prompt, tokenizer: context.tokenizer)
        let start = startingState(for: tokens, tag: tag)
        TimingLog.mark(
            "cleanup-prompt",
            "prompt-tokens=\(tokens.count) prefill-tokens=\(start.input.count) prefix-hit=\(start.cache != nil) max-tokens=\(prompt.maximumTokens) \(TimingLog.executionContext)",
        )
        let parameters = GenerateParameters(
            maxTokens: prompt.maximumTokens,
            temperature: Float(prompt.temperature),
        )
        return try decode(
            input: start.input,
            cache: start.cache,
            parameters: parameters,
            tag: tag,
        )
    }

    func unload() {
        memory.begin()
        context = nil
        prefixes = [:]
        Memory.clearCache()
    }

    private func startingState(
        for tokens: [Int],
        tag: OutputTag,
    ) -> (input: [Int], cache: [any KVCache]?) {
        guard let prefix = prefixes[tag], let suffix = prefix.suffix(of: tokens) else {
            return (tokens, nil)
        }
        return (suffix, prefix.copiedLayers())
    }

    private func makePrefixCache(
        tag: OutputTag,
        context: ModelContext,
    ) throws(CleanupError) -> PrefixCache {
        let probes =
            switch tag {
            case .cleaned: PrefixProbes.cleanup(using: builder)
            case .edited: PrefixProbes.edit(using: builder)
            }
        var sequences: [[Int]] = []
        for probe in probes {
            sequences.append(try promptTokens(probe, tokenizer: context.tokenizer))
        }
        let shared = sequences.dropFirst()
            .reduce(sequences[0]) { common, next in
                Array(zip(common, next).prefix { $0 == $1 }.map { $0.0 })
            }
        do {
            let parameters = GenerateParameters(maxTokens: 1, temperature: 0)
            let layers = try context.model.newCache(parameters: parameters)
            _ = try TokenIterator(
                input: LMInput(tokens: MLXArray(shared)),
                model: context.model,
                cache: layers,
                parameters: parameters,
            )
            eval(layers)
            return PrefixCache(tokens: shared, layers: layers)
        } catch {
            throw .failed(code: (error as NSError).code)
        }
    }

    private func promptTokens(
        _ prompt: CleanupPrompt,
        tokenizer: any MLXLMCommon.Tokenizer,
    ) throws(CleanupError) -> [Int] {
        do {
            let rendered = try tokenizer.applyChatTemplate(
                messages: ChatTurns.make(from: prompt.messages),
                tools: nil,
                additionalContext: ChatTurns.additionalContext,
            )
            return rendered
                + tokenizer.encode(text: prompt.assistantPrefill, addSpecialTokens: false)
        } catch {
            throw .failed(code: (error as NSError).code)
        }
    }

    private static func markDecode(
        from start: ContinuousClock.Instant,
        loopStart: ContinuousClock.Instant,
        tokens: Int,
    ) {
        TimingLog.mark(
            "cleanup-decoded-tokens",
            "prefill-ms=\(start.duration(to: loopStart).milliseconds) generated-tokens=\(tokens) loop-ms=\(loopStart.duration(to: .now).milliseconds)",
        )
    }

    private static func endTokens(of context: ModelContext) -> Set<Int> {
        context.configuration.eosTokenIds.union([context.tokenizer.eosTokenId].compactMap { $0 })
    }

    private func decode(
        input: [Int],
        cache: [any KVCache]?,
        parameters: GenerateParameters,
        tag: OutputTag,
    ) throws(CleanupError) -> GeneratedText {
        guard let context else { throw .modelUnavailable }
        let stop = StopSequence(closing: tag)
        let budget = GenerationBudget(maximumTokens: parameters.maxTokens ?? 0)
        let endTokens = Self.endTokens(of: context)
        var generated: [Int] = []
        var hasStopped = false
        let clock = ContinuousClock()
        let decodeStart = clock.now
        do {
            var iterator = try TokenIterator(
                input: LMInput(tokens: MLXArray(input)),
                model: context.model,
                cache: cache,
                parameters: parameters,
            )
            let loopStart = clock.now
            defer {
                Self.markDecode(from: decodeStart, loopStart: loopStart, tokens: generated.count)
            }
            while let token = iterator.next(), !endTokens.contains(token) {
                if Task.isCancelled { throw CleanupError.cancelled }
                generated.append(token)
                let tail = context.tokenizer.decode(
                    tokenIds: Array(generated.suffix(StopSequence.tailTokenCount)),
                    skipSpecialTokens: false,
                )
                hasStopped = stop.isReached(in: tail)
                if hasStopped { break }
            }
        } catch let error as CleanupError {
            throw error
        } catch {
            throw .failed(code: (error as NSError).code)
        }
        return GeneratedText(
            text: context.tokenizer.decode(tokenIds: generated, skipSpecialTokens: false),
            reachedTokenLimit: !hasStopped && budget.isExhausted(afterGenerating: generated.count),
        )
    }
}
