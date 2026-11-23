public struct CleanupPrompt: Hashable, Sendable {
    public let messages: [PromptMessage]
    public let assistantPrefill: String
    public let temperature: Double
    public let maximumTokens: Int

    public init(
        messages: [PromptMessage],
        assistantPrefill: String,
        temperature: Double,
        maximumTokens: Int,
    ) {
        self.messages = messages
        self.assistantPrefill = assistantPrefill
        self.temperature = temperature
        self.maximumTokens = maximumTokens
    }

    public var userText: String {
        messages.last { $0.role == .user }?.content ?? ""
    }

    public var instructionsText: String {
        let system = messages.first { $0.role == .system }?.content ?? ""
        let turns = messages.dropFirst().dropLast()
        var examples: [String] = []
        for turn in turns {
            switch turn.role {
            case .user: examples.append("Input:\n\(turn.content)")
            case .assistant: examples.append("Output:\n\(turn.content)")
            case .system: break
            }
        }
        return ([system, PromptText.examplesHeader] + examples).joined(separator: "\n\n")
    }
}
