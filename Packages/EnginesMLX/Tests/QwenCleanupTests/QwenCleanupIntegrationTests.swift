import Core
import Foundation
@testable import QwenCleanup
import Testing

private let modelDirectory = ProcessInfo.processInfo.environment["QWEN_CLEANUP_MODEL_DIR"]

@Suite(.enabled(if: modelDirectory != nil))
internal struct QwenCleanupIntegrationTests {
    private func makeRequest(_ text: String) -> CleanupRequest {
        CleanupRequest(
            text: text,
            dictionary: [],
            contextBefore: "",
            languages: [Locale(identifier: "ko")],
            timeBudget: .seconds(5),
        )
    }

    @Test
    func cleansWithPrefixCacheAndKeepsQuestionsAsQuestions() async throws {
        let directory = try #require(modelDirectory)
        let engine = QwenCleanupEngine(
            directory: URL(fileURLWithPath: directory),
            gate: InferenceGate(),
        )
        try await engine.prepare()
        let first = try await engine.clean(makeRequest("내일 서울 날씨가 어때"))
        let second = try await engine.clean(makeRequest("내일 서울 날씨가 어때"))
        #expect(first == second)
        #expect(first.contains("날씨"))
        #expect(!first.contains("<cleaned>"))
        #expect(!first.contains("</cleaned>"))
        await engine.unload()
    }

    @Test
    func editsASelection() async throws {
        let directory = try #require(modelDirectory)
        let engine = QwenCleanupEngine(
            directory: URL(fileURLWithPath: directory),
            gate: InferenceGate(),
        )
        let edited = try await engine.edit(
            EditRequest(
                selection: "the meeting is on tuesday",
                instruction: "make it formal",
                timeBudget: .seconds(5),
            )
        )
        #expect(!edited.isEmpty)
        await engine.unload()
    }
}
