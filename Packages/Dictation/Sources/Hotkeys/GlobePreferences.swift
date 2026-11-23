internal protocol GlobePreferences: Sendable {
    func fnUsageType() -> Int?
    func enabledInputSourceKinds() -> [String]
}
