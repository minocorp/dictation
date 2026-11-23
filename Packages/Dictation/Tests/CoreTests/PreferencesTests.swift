import Core
import Foundation
import Testing

internal struct PreferencesTests {
    private let languages = [Locale(identifier: "ko_KR"), Locale(identifier: "en_US")]

    @Test
    func defaultsMatchSpecification() {
        let preferences = Preferences.makeDefault(
            globeSwitchesInputSource: false,
            preferredLanguages: languages,
        )
        #expect(preferences.dictateKey == .fn)
        #expect(preferences.pasteLastShortcut == KeyBinding.pasteLastDefault)
        #expect(preferences.pasteLastShortcut.modifiers == [.control, .command])
        #expect(preferences.microphone == .builtIn)
        #expect(preferences.languages == languages)
        #expect(preferences.cleanup)
        #expect(preferences.sounds)
        #expect(preferences.launchAtLogin)
        #expect(preferences.handsFreeSilenceLimit.duration == .seconds(120))
        #expect(preferences.historyRetention.days == 30)
        #expect(preferences.learning)
        #expect(preferences.speechModel == .recommended)
        #expect(preferences.cleanupModel == .recommended)
    }

    @Test
    func globeSwitchingInputSourceSelectsRightOption() {
        let preferences = Preferences.makeDefault(
            globeSwitchesInputSource: true,
            preferredLanguages: languages,
        )
        #expect(preferences.dictateKey == .rightOption)
    }

    @Test
    func roundTripsEveryKindOfValueThroughJSON() throws {
        var preferences = Preferences.makeDefault(
            globeSwitchesInputSource: false,
            preferredLanguages: languages,
        )
        preferences.dictateKey = KeyBinding(trigger: .mouseButton(4), modifiers: [.shift])
        preferences.microphone = .device(uid: "BuiltInMicrophoneDevice")
        preferences.handsFreeSilenceLimit = .never
        preferences.historyRetention = .off
        preferences.speechModel = .model(id: "qwen3-asr-1.7b-8bit")
        preferences.cleanup = false

        let encoded = try JSONEncoder().encode(preferences)
        #expect(try JSONDecoder().decode(Preferences.self, from: encoded) == preferences)
    }

    @Test(arguments: [
        (HandsFreeSilenceLimit.seconds30, Duration.seconds(30)),
        (.minutes2, .seconds(120)),
        (.minutes10, .seconds(600)),
    ])
    func silenceLimitDuration(limit: HandsFreeSilenceLimit, expected: Duration) {
        #expect(limit.duration == expected)
    }

    @Test
    func neverSilenceLimitHasNoDuration() {
        #expect(HandsFreeSilenceLimit.never.duration == nil)
    }

    @Test(arguments: [(HistoryRetention.off, 0), (.oneDay, 1), (.thirtyDays, 30)])
    func retentionDays(retention: HistoryRetention, expected: Int) {
        #expect(retention.days == expected)
    }
}
