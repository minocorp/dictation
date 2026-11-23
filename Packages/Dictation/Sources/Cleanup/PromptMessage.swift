public struct PromptMessage: Hashable, Sendable {
    public let role: PromptRole
    public let content: String

    public init(role: PromptRole, content: String) {
        self.role = role
        self.content = content
    }
}
