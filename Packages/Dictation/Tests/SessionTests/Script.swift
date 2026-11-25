import Core
@testable import Session

internal enum Script {
    static let tapThreshold = Duration.milliseconds(300)
    static let doubleTapWindow = Duration.milliseconds(400)
    static let processingDelay = Duration.milliseconds(250)
    static let startCapture = Effect.startCapture(Fixture.first, device: .builtIn)
    static let tapOnly = Fixture.gesture(.pressBegan)
    static let soundsOff: Event = {
        var preferences = Fixture.preferences
        preferences.sounds = false
        return .system(.preferences(preferences))
    }()
    static let afterTap = [tapOnly, Fixture.gesture(.released)]
    static let handsFree = afterTap + [Fixture.gesture(.handsFreeBegan)]
    static let live = Fixture.holdAndRelease()
    static let liveWithSegments =
        live + [
            Fixture.input(.segment(Fixture.segment(0))),
            Fixture.input(.segment(Fixture.segment(1))),
        ]
    static let finishEffects: [Effect] = [
        .stopCapture(Fixture.first),
        .play(.finish),
        .startTimer(.processingDelay, processingDelay),
        .setTapPolicy(Fixture.policy(swallowsEscape: false)),
    ]

    static func transcribeEffect(_ index: Int) -> Effect {
        .transcribe(Fixture.segment(index), languages: Fixture.languages)
    }
}
