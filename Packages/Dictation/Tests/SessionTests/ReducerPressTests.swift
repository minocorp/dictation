import Core
@testable import Session
import Testing

internal struct ReducerPressTests {
    private static let pressCases: [ReducerCase] = [
        ReducerCase(
            "press starts capture",
            event: Script.tapOnly,
            effects: [
                .readFocus(Fixture.first),
                Script.startCapture,
                .startTimer(.tapThreshold, Script.tapThreshold),
                .setTapPolicy(Fixture.policy(swallowsEscape: true)),
            ],
            hud: .listening,
            isLive: true,
        ),
        ReducerCase(
            "press while live is ignored",
            setup: [Script.tapOnly],
            event: Fixture.gesture(.pressBegan, Fixture.second),
            effects: [],
            hud: .listening,
            isLive: true,
        ),
        ReducerCase(
            "press dismisses the previous notice",
            setup: [Script.tapOnly, Fixture.gesture(.cancel)],
            event: Fixture.gesture(.pressBegan, Fixture.second),
            effects: [
                .cancelTimer(.hudExpiry),
                .readFocus(Fixture.second),
                .startCapture(Fixture.second, device: .builtIn),
                .startTimer(.tapThreshold, Script.tapThreshold),
                .setTapPolicy(Fixture.policy(swallowsEscape: true)),
            ],
            hud: .listening,
            isLive: true,
        ),
        ReducerCase(
            "press with Accessibility off shows a problem",
            setup: [
                .system(
                    .permission(
                        PermissionStatus(microphone: .granted, isAccessibilityTrusted: false)
                    )
                )
            ],
            event: Script.tapOnly,
            effects: [.startTimer(.hudExpiry, .seconds(8))],
            hud: .problem(.accessibilityOff),
            isLive: false,
        ),
        ReducerCase(
            "press with microphone denied shows a problem",
            setup: [
                .system(
                    .permission(
                        PermissionStatus(microphone: .denied, isAccessibilityTrusted: true)
                    )
                )
            ],
            event: Script.tapOnly,
            effects: [.startTimer(.hudExpiry, .seconds(8))],
            hud: .problem(.microphoneDenied),
            isLive: false,
        ),
        ReducerCase(
            "capture started plays the start sound",
            setup: [Script.tapOnly],
            event: Fixture.input(.started),
            effects: [.play(.start)],
            hud: .listening,
            isLive: true,
        ),
        ReducerCase(
            "capture started is silent with sounds off",
            setup: [Script.soundsOff, Script.tapOnly],
            event: Fixture.input(.started),
            effects: [],
            hud: .listening,
            isLive: true,
        ),
        ReducerCase(
            "capture failure at start shows microphone unavailable",
            setup: [Script.tapOnly],
            event: Fixture.result(.failed(.capture(.deviceUnavailable))),
            effects: [
                .cancelTimer(.tapThreshold),
                .cancelWork(Fixture.first),
                .startTimer(.hudExpiry, .seconds(8)),
                .setTapPolicy(Fixture.policy(swallowsEscape: false)),
            ],
            hud: .problem(.microphoneUnavailable),
            isLive: false,
        ),
        ReducerCase(
            "cancelled capture failure is ignored",
            setup: [Script.tapOnly],
            event: Fixture.result(.failed(.capture(.cancelled))),
            effects: [],
            hud: .listening,
            isLive: true,
        ),
    ]

    @Test(arguments: pressCases)
    func pressPaths(_ scenario: ReducerCase) {
        scenario.check()
    }
}
