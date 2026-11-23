public struct EditRequest: Hashable, Sendable {
    public let selection: String
    public let instruction: String
    public let timeBudget: Duration

    public init(selection: String, instruction: String, timeBudget: Duration) {
        self.selection = selection
        self.instruction = instruction
        self.timeBudget = timeBudget
    }
}
