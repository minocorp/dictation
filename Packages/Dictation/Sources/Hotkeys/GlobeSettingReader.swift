public struct GlobeSettingReader: Sendable {
    private static let selectableKinds: Set<String> = ["Keyboard Layout", "Input Mode"]

    private let preferences: any GlobePreferences

    public init() {
        self.init(preferences: SystemGlobePreferences())
    }

    init(preferences: any GlobePreferences) {
        self.preferences = preferences
    }

    public func read() -> GlobeSetting {
        if let value = preferences.fnUsageType() {
            return GlobeSetting(usage: GlobeUsage(fnUsageType: value))
        }
        let selectableCount = preferences.enabledInputSourceKinds()
            .filter { Self.selectableKinds.contains($0) }
            .count
        return GlobeSetting(usage: selectableCount > 1 ? .changeInputSource : .showEmojiAndSymbols)
    }
}
