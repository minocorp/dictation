public struct EditRequest: Hashable, Sendable {
    public let selection: String
    public let instruction: String

    public init(selection: String, instruction: String) {
        self.selection = selection
        self.instruction = instruction
    }
}
