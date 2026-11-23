public import Foundation

public struct Preferences: Codable, Hashable, Sendable {
    public var dictateKey: KeyBinding
    public var pasteLastShortcut: KeyBinding
    public var microphone: InputDevice
    public var languages: [Locale]
    public var cleanup: Bool
    public var sounds: Bool
    public var launchAtLogin: Bool
    public var handsFreeSilenceLimit: HandsFreeSilenceLimit
    public var historyRetention: HistoryRetention
    public var learning: Bool
    public var speechModel: ModelChoice
    public var cleanupModel: ModelChoice

    public static func makeDefault(
        globeSwitchesInputSource: Bool,
        preferredLanguages: [Locale],
    ) -> Preferences {
        Preferences(
            dictateKey: globeSwitchesInputSource ? .rightOption : .fn,
            pasteLastShortcut: .pasteLastDefault,
            microphone: .builtIn,
            languages: preferredLanguages,
            cleanup: true,
            sounds: true,
            launchAtLogin: true,
            handsFreeSilenceLimit: .minutes2,
            historyRetention: .thirtyDays,
            learning: true,
            speechModel: .recommended,
            cleanupModel: .recommended,
        )
    }
}
