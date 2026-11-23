public enum HistoryRetention: String, Codable, Hashable, Sendable, CaseIterable {
    case off
    case oneDay
    case thirtyDays

    public var days: Int {
        switch self {
        case .off: 0
        case .oneDay: 1
        case .thirtyDays: 30
        }
    }
}
