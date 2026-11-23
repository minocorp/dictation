public enum ModelChoice: Codable, Hashable, Sendable {
    case recommended
    case model(id: String)
}
