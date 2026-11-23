public enum GlobeUsage: Hashable, Sendable {
    case doNothing
    case changeInputSource
    case showEmojiAndSymbols
    case startDictation
    case other(Int)

    private static let byFnUsageType: [Int: GlobeUsage] = [
        0: .doNothing,
        1: .changeInputSource,
        2: .showEmojiAndSymbols,
        3: .startDictation,
    ]

    init(fnUsageType: Int) {
        self = Self.byFnUsageType[fnUsageType] ?? .other(fnUsageType)
    }
}
