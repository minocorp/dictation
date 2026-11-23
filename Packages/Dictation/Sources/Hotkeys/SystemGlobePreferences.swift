import Foundation

internal struct SystemGlobePreferences: GlobePreferences {
    func fnUsageType() -> Int? {
        value(for: "AppleFnUsageType") as? Int
    }

    func enabledInputSourceKinds() -> [String] {
        let sources = value(for: "AppleEnabledInputSources") as? [[String: Any]]
        return (sources ?? []).compactMap { $0["InputSourceKind"] as? String }
    }

    private func value(for key: String) -> Any? {
        CFPreferencesCopyAppValue(key as CFString, "com.apple.HIToolbox" as CFString)
    }
}
