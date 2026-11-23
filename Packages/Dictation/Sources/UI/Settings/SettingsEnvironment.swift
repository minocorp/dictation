public import Core
public import Foundation

public struct SettingsEnvironment {
    let apply: @MainActor (Preferences) -> Void
    let microphones: @MainActor () -> [MicrophoneOption]
    let languages: @MainActor () async -> [Locale]
    let captureKeys: @MainActor () -> AsyncStream<RawKeyEvent>
    let globeAdvice: @MainActor () -> GlobeAdvice
    let openKeyboardSettings: @MainActor () -> Void
    let clearHistory: @MainActor () async -> Void

    public init(
        apply: @escaping @MainActor (Preferences) -> Void,
        microphones: @escaping @MainActor () -> [MicrophoneOption],
        languages: @escaping @MainActor () async -> [Locale],
        captureKeys: @escaping @MainActor () -> AsyncStream<RawKeyEvent>,
        globeAdvice: @escaping @MainActor () -> GlobeAdvice,
        openKeyboardSettings: @escaping @MainActor () -> Void,
        clearHistory: @escaping @MainActor () async -> Void,
    ) {
        self.apply = apply
        self.microphones = microphones
        self.languages = languages
        self.captureKeys = captureKeys
        self.globeAdvice = globeAdvice
        self.openKeyboardSettings = openKeyboardSettings
        self.clearHistory = clearHistory
    }
}
