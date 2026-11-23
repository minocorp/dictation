public import Cleanup
public import Core
public import Foundation
public import ModelCatalog

public final class QwenCleanupEngine: CleanupEngine {
    public static let kind = "qwen3.5"

    private let directory: URL
    private let gate: InferenceGate
    private let builder: PromptBuilder
    private let parser = OutputParser()
    private let runtime: QwenCleanupRuntime

    public init(
        directory: URL,
        gate: InferenceGate,
        builder: PromptBuilder = PromptBuilder(),
    ) {
        self.directory = directory
        self.gate = gate
        self.builder = builder
        runtime = QwenCleanupRuntime(builder: builder)
    }

    public static func register(in registry: EngineRegistry, gate: InferenceGate) {
        registry.registerCleanup(kind: kind) { _, directory in
            QwenCleanupEngine(directory: directory, gate: gate)
        }
    }

    public func prepare() async throws(CleanupError) {
        try await gate.run { () async throws(CleanupError) in
            try await runtime.load(from: directory)
            try await runtime.prefill(.cleaned)
            try await runtime.warmUp(.cleaned)
        }
    }

    public func clean(_ request: CleanupRequest) async throws(CleanupError) -> String {
        let prompt = builder.cleanupPrompt(for: request, profile: .mlx)
        return try await run(prompt, tag: .cleaned)
    }

    public func edit(_ request: EditRequest) async throws(CleanupError) -> String {
        let prompt = builder.editPrompt(for: request)
        return try await run(prompt, tag: .edited)
    }

    public func preheat() async {
        do throws(CleanupError) {
            try await UserInitiated.run { [self] () async throws(CleanupError) in
                try await gate.run { () async throws(CleanupError) in
                    TimingLog.mark("cleanup-preheat-start", TimingLog.executionContext)
                    try await runtime.warmUp(.cleaned)
                    TimingLog.mark("cleanup-preheat-end")
                }
            }
        } catch {
            TimingLog.mark("cleanup-preheat-end", "cancelled")
        }
    }

    public func unload() async {
        await runtime.unload()
    }

    private func run(_ prompt: CleanupPrompt, tag: OutputTag) async throws(CleanupError) -> String {
        let generated = try await UserInitiated.run { [self] () async throws(CleanupError) in
            try await generate(prompt, tag: tag)
        }
        let parsed = parser.parse(
            generated.text,
            tag: tag,
            reachedTokenLimit: generated.reachedTokenLimit,
        )
        guard let parsed else { throw .rejected }
        return parsed.text
    }

    private func generate(
        _ prompt: CleanupPrompt,
        tag: OutputTag,
    ) async throws(CleanupError) -> GeneratedText {
        let requested = ContinuousClock.now
        return try await gate.run { () async throws(CleanupError) -> GeneratedText in
            TimingLog.mark(
                "cleanup-gate-acquired",
                "wait-ms=\(requested.duration(to: .now).milliseconds) \(TimingLog.executionContext)",
            )
            try await runtime.load(from: directory)
            let text = try await runtime.generate(prompt, tag: tag)
            TimingLog.mark("cleanup-decoded")
            return text
        }
    }
}
