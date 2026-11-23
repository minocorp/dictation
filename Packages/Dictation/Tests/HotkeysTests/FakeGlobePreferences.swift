@testable import Hotkeys

internal struct FakeGlobePreferences: GlobePreferences {
    let usageType: Int?
    let sourceKinds: [String]

    func fnUsageType() -> Int? { usageType }
    func enabledInputSourceKinds() -> [String] { sourceKinds }
}
