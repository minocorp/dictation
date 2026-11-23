public enum RAMTier: String, Codable, Hashable, Sendable {
    private static let mediumTierGB = 16
    private static let largeTierGB = 24

    case ram8 = "ram-8"
    case ram16 = "ram-16"
    case ram24 = "ram-24"

    public init(ramGB: Int) {
        if ramGB < Self.mediumTierGB {
            self = .ram8
        } else if ramGB < Self.largeTierGB {
            self = .ram16
        } else {
            self = .ram24
        }
    }
}
