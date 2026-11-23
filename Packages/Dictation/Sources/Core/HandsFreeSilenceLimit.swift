public enum HandsFreeSilenceLimit: String, Codable, Hashable, Sendable, CaseIterable {
    case seconds30
    case minutes2
    case minutes10
    case never

    public var duration: Duration? {
        switch self {
        case .seconds30: .seconds(30)
        case .minutes2: .seconds(120)
        case .minutes10: .seconds(600)
        case .never: nil
        }
    }
}
