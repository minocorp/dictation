import Cleanup

internal enum ChatTurns {
    static let additionalContext: [String: any Sendable] = ["enable_thinking": false]

    static func make(from messages: [PromptMessage]) -> [[String: any Sendable]] {
        messages.map { message in
            ["role": roleName(of: message.role), "content": message.content]
        }
    }

    private static func roleName(of role: PromptRole) -> String {
        switch role {
        case .system: "system"
        case .user: "user"
        case .assistant: "assistant"
        }
    }
}
