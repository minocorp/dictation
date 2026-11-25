import Core
import Foundation
import Testing
@testable import UI

@MainActor
internal struct SettingsModelTests {
    private final class Applied {
        var values: [Preferences] = []
        var optionOpened = 0
    }

    private let applied = Applied()
    private let english = Locale(identifier: "en_US")
    private let korean = Locale(identifier: "ko_KR")
    private let japanese = Locale(identifier: "ja_JP")

    private func makeModel(advice: GlobeAdvice = .none) -> SettingsModel {
        let applied = applied
        let languages = [english, korean, japanese]
        return SettingsModel(
            preferences: .makeDefault(
                globeSwitchesInputSource: false,
                preferredLanguages: [english, korean],
            ),
            environment: SettingsEnvironment(
                apply: { applied.values.append($0) },
                microphones: { [MicrophoneOption.builtIn] },
                languages: { languages },
                captureKeys: { AsyncStream { $0.finish() } },
                globeAdvice: { advice },
                openKeyboardSettings: { applied.optionOpened += 1 },
                clearHistory: {},
            ),
        )
    }

    @Test
    func changingAPreferenceAppliesIt() {
        let model = makeModel()
        model.preferences.cleanup = false
        #expect(applied.values.count == 1)
        #expect(applied.values.first?.cleanup == false)
    }

    @Test
    func assigningTheSameValueDoesNotApplyAgain() {
        let model = makeModel()
        model.preferences.cleanup = true
        #expect(applied.values.isEmpty)
    }

    @Test
    func addableLanguagesExcludeSelectedOnes() async {
        let model = makeModel()
        await model.refresh()
        #expect(model.addableLanguages.map(\.identifier) == ["ja_JP"])
        model.addLanguage(japanese)
        #expect(model.addableLanguages.isEmpty)
    }

    @Test
    func lastLanguageCannotBeRemoved() {
        let model = makeModel()
        model.removeLanguage(english)
        model.removeLanguage(korean)
        #expect(model.preferences.languages.map(\.identifier) == ["ko_KR"])
    }

    @Test
    func recordersReadAndWriteTheirBindings() {
        let model = makeModel()
        let recorder = model.makeRecorder(.dictateKey)
        #expect(recorder.currentLabel == KeyBinding.fn.label)
        #expect(recorder.receive(UIFixtures.event(code: 61, modifiers: [.option])))
        #expect(model.preferences.dictateKey == .rightOption)
        let shortcut = model.makeRecorder(.shortcut)
        #expect(shortcut.receive(UIFixtures.event(code: 2, modifiers: [.command])))
        #expect(model.preferences.pasteLastShortcut.modifiers == [.command])
    }

    @Test
    func globeAdviceOnlyAppliesToTheFnKey() {
        let model = makeModel(advice: .changesInputSource)
        #expect(model.globeAdvice == .changesInputSource)
        model.useRightOption()
        #expect(model.globeAdvice == .none)
    }

    @Test
    func openingKeyboardSettingsForwards() {
        makeModel().openKeyboardSettings()
        #expect(applied.optionOpened == 1)
    }
}
