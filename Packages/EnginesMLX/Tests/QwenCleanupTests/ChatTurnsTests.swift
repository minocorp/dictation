import Cleanup
import Core
@testable import QwenCleanup
import Testing

internal struct ChatTurnsTests {
    private let request = CleanupRequest(
        text: "음 내일 회의 세 시",
        dictionary: [Word(text: "Supabase", soundsLike: ["super base"], source: .manual)],
        contextBefore: "앞 문장.",
        languages: [],
    )

    @Test
    func thinkingIsDisabledExplicitly() {
        let value = ChatTurns.additionalContext["enable_thinking"] as? Bool
        #expect(value == false)
    }

    @Test
    func turnsFollowPromptMessagesInOrder() throws {
        let prompt = PromptBuilder().cleanupPrompt(for: request, profile: .mlx)
        let turns = ChatTurns.make(from: prompt.messages)
        #expect(turns.count == prompt.messages.count)
        #expect(turns.first?["role"] as? String == "system")
        #expect(turns.last?["role"] as? String == "user")
        let last = try #require(turns.last?["content"] as? String)
        #expect(last.contains("<transcript>음 내일 회의 세 시</transcript>"))
        #expect(last.contains("<dictionary>Supabase</dictionary>"))
        #expect(!last.contains("super base"))
    }

    @Test
    func fewShotTurnsAlternateUserAndAssistant() {
        let prompt = PromptBuilder().cleanupPrompt(for: request, profile: .mlx)
        let roles = ChatTurns.make(from: prompt.messages).compactMap { $0["role"] as? String }
        let body = roles.dropFirst()
        for (index, role) in body.enumerated() {
            #expect(role == (index.isMultiple(of: 2) ? "user" : "assistant"))
        }
    }

    @Test
    func mlxProfileKeepsAllFewShots() {
        let mlx = PromptBuilder().cleanupPrompt(for: request, profile: .mlx)
        let apple = PromptBuilder().cleanupPrompt(for: request, profile: .foundationModels)
        #expect(mlx.messages.count > apple.messages.count)
        #expect(mlx.assistantPrefill == "<cleaned>")
    }
}
