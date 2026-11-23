import Core
@testable import Session
import Testing

internal struct ReducerSystemTests {
    private static let first = Fixture.first
    private static let sleepingEffects: [Effect] = [
        .stopCapture(first),
        .play(.finish),
        .setTapPolicy(Fixture.policy(swallowsEscape: false)),
    ]
    private static let denied = PermissionStatus(microphone: .denied, isAccessibilityTrusted: true)
    private static let untrusted = PermissionStatus(
        microphone: .granted,
        isAccessibilityTrusted: false,
    )

    private static let deniedAndUntrusted = PermissionStatus(
        microphone: .denied,
        isAccessibilityTrusted: false,
    )

    private static let cases: [ReducerCase] = [
        ReducerCase(
            "sleep finishes the capture without a HUD",
            setup: Fixture.holdAndRelease(),
            event: .system(.systemSleep),
            effects: sleepingEffects,
            hud: .hidden,
            isLive: false,
        ),
        ReducerCase(
            "screen lock finishes the capture without a HUD",
            setup: Fixture.holdAndRelease(),
            event: .system(.screenLocked),
            effects: sleepingEffects,
            hud: .hidden,
            isLive: false,
        ),
        ReducerCase(
            "sleep with nothing live changes nothing",
            event: .system(.systemSleep),
            effects: [],
            hud: .hidden,
            isLive: false,
        ),
        ReducerCase(
            "granting the microphone clears the denied problem",
            setup: [.system(.permission(denied)), Fixture.gesture(.pressBegan)],
            event: .system(.permission(Fixture.granted)),
            effects: [.cancelTimer(.hudExpiry)],
            hud: .hidden,
            isLive: false,
        ),
        ReducerCase(
            "trusting Accessibility clears the Accessibility problem",
            setup: [.system(.permission(untrusted)), Fixture.gesture(.pressBegan)],
            event: .system(.permission(Fixture.granted)),
            effects: [.cancelTimer(.hudExpiry)],
            hud: .hidden,
            isLive: false,
        ),
        ReducerCase(
            "an unrelated permission change keeps the problem",
            setup: [.system(.permission(denied)), Fixture.gesture(.pressBegan)],
            event: .system(.permission(deniedAndUntrusted)),
            effects: [],
            hud: .problem(.microphoneDenied),
            isLive: false,
        ),
        ReducerCase(
            "event tap failure shows the Accessibility problem",
            event: .system(.hotkeyFailed(.eventTapUnavailable)),
            effects: [.startTimer(.hudExpiry, .seconds(8))],
            hud: .problem(.accessibilityOff),
            isLive: false,
        ),
        ReducerCase(
            "problem expires after 8 seconds",
            setup: [.system(.hotkeyFailed(.eventTapUnavailable))],
            event: .timer(.hudExpiry),
            effects: [],
            hud: .hidden,
            isLive: false,
        ),
    ]

    @Test(arguments: cases)
    func systemPaths(_ scenario: ReducerCase) {
        scenario.check()
    }

    @Test
    func sleepDuringCaptureKeepsTheResultWithoutInserting() throws {
        let events =
            Fixture.holdAndRelease() + [
                Fixture.input(.segment(Fixture.segment(0))),
                .system(.systemSleep),
                Fixture.input(.segmentsEnded),
                Fixture.transcribed(0, "hello"),
                Fixture.cleaned(0, "Hello."),
                Fixture.input(.finished(audioURL: Fixture.audioURL)),
            ]
        let result = Fixture.play(events)
        let kept = Fixture.item(raw: "hello", final: "Hello.", status: .recovered)
        #expect(result.effects == [.save(kept)])
        #expect(try #require(result.state.lastResult).item == kept)
        #expect(result.state.isIdle)
    }

    @Test
    func lockingKeepsAQueuedDictationFromInserting() {
        let events =
            Fixture.holdAndRelease() + [
                Fixture.input(.segment(Fixture.segment(0))),
                Fixture.gesture(.released),
                .system(.screenLocked),
                Fixture.input(.segmentsEnded),
                Fixture.transcribed(0, "hello"),
                Fixture.cleaned(0, "Hello."),
                Fixture.input(.finished(audioURL: Fixture.audioURL)),
            ]
        let result = Fixture.play(events)
        #expect(!result.effects.contains { if case .insert = $0 { true } else { false } })
        #expect(result.state.lastResult?.item.status == .recovered)
    }

    @Test
    func changedDictateKeyUpdatesTheTapPolicy() {
        var preferences = Fixture.preferences
        preferences.dictateKey = .rightOption
        let result = Fixture.play([.system(.preferences(preferences))])
        let policy = TapPolicy(
            dictateKey: .rightOption,
            pasteLast: preferences.pasteLastShortcut,
            swallowsEscape: false,
        )
        #expect(result.effects == [.setTapPolicy(policy)])
    }
}
