public import Core
public import Foundation
public import Observation

@MainActor
@Observable
public final class SettingsModel {
    public var preferences: Preferences {
        didSet {
            guard preferences != oldValue else { return }
            environment.apply(preferences)
        }
    }

    public private(set) var microphones: [MicrophoneOption] = []
    public private(set) var availableLanguages: [Locale] = []

    @ObservationIgnored
    private let environment: SettingsEnvironment

    public init(preferences: Preferences, environment: SettingsEnvironment) {
        self.preferences = preferences
        self.environment = environment
    }

    var globeAdvice: GlobeAdvice {
        preferences.dictateKey == .fn ? environment.globeAdvice() : .none
    }

    public var addableLanguages: [Locale] {
        var seen = Set(preferences.languages.map(languageCode))
        return availableLanguages.filter { seen.insert(languageCode($0)).inserted }
    }

    public func refresh() async {
        microphones = environment.microphones()
        availableLanguages = await environment.languages()
    }

    public func makeRecorder(_ kind: KeyRecorderKind) -> KeyRecorderModel {
        switch kind {
        case .dictateKey:
            KeyRecorderModel(
                kind: kind,
                defaultBinding: .fn,
                binding: { [weak self] in self?.preferences.dictateKey ?? .fn },
                capture: environment.captureKeys,
                commit: { [weak self] in self?.preferences.dictateKey = $0 },
            )
        case .shortcut:
            KeyRecorderModel(
                kind: kind,
                defaultBinding: .pasteLastDefault,
                binding: { [weak self] in self?.preferences.pasteLastShortcut ?? .pasteLastDefault
                },
                capture: environment.captureKeys,
                commit: { [weak self] in self?.preferences.pasteLastShortcut = $0 },
            )
        }
    }

    public func addLanguage(_ language: Locale) {
        preferences.languages.append(language)
    }

    public func removeLanguage(_ language: Locale) {
        guard preferences.languages.count > 1 else { return }
        preferences.languages.removeAll { $0.identifier == language.identifier }
    }

    public func languageName(_ language: Locale) -> String {
        let code = languageCode(language)
        return Locale.current.localizedString(forLanguageCode: code) ?? code
    }

    private func languageCode(_ language: Locale) -> String {
        language.language.languageCode?.identifier ?? language.identifier
    }

    public func openKeyboardSettings() {
        environment.openKeyboardSettings()
    }

    public func clearHistory() async {
        await environment.clearHistory()
    }

    public func useRightOption() {
        preferences.dictateKey = .rightOption
    }
}
