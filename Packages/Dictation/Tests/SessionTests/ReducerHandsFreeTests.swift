import Core
@testable import Session
import Testing

internal struct ReducerHandsFreeTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let limit: HandsFreeSilenceLimit
        let ticks: Int
        let hud: HUDState
        let isLive: Bool

        var testDescription: String { "\(limit) after \(ticks) ticks" }
    }

    private static let cases: [Case] = [
        Case(
            limit: .seconds30,
            ticks: 1,
            hud: .handsFree(elapsed: .seconds(1), countdown: nil),
            isLive: true,
        ),
        Case(
            limit: .seconds30,
            ticks: 19,
            hud: .handsFree(elapsed: .seconds(19), countdown: nil),
            isLive: true,
        ),
        Case(
            limit: .seconds30,
            ticks: 20,
            hud: .handsFree(elapsed: .seconds(20), countdown: .seconds(10)),
            isLive: true,
        ),
        Case(
            limit: .seconds30,
            ticks: 29,
            hud: .handsFree(elapsed: .seconds(29), countdown: .seconds(1)),
            isLive: true,
        ),
        Case(limit: .seconds30, ticks: 30, hud: .hidden, isLive: false),
        Case(
            limit: .never,
            ticks: 3_600,
            hud: .handsFree(elapsed: .seconds(3_600), countdown: nil),
            isLive: true,
        ),
        Case(
            limit: .minutes2,
            ticks: 110,
            hud: .handsFree(elapsed: .seconds(110), countdown: .seconds(10)),
            isLive: true,
        ),
    ]

    private static func handsFreeState(limit: HandsFreeSilenceLimit) -> SessionState {
        var preferences = Fixture.preferences
        preferences.handsFreeSilenceLimit = limit
        var state = Fixture.state()
        let setup: [Event] = [
            .system(.preferences(preferences)),
            Fixture.gesture(.pressBegan),
            Fixture.gesture(.released),
            Fixture.gesture(.handsFreeBegan),
        ]
        for event in setup {
            _ = reduce(&state, event)
        }
        return state
    }

    @Test(arguments: cases)
    func silenceLimitAndCountdown(_ scenario: Case) {
        var state = Self.handsFreeState(limit: scenario.limit)
        for _ in 0..<scenario.ticks {
            _ = reduce(&state, .timer(.handsFreeSecond))
        }
        #expect(state.hud == scenario.hud)
        #expect(state.isLive == scenario.isLive)
    }

    @Test
    func tickRearmsTheSecondTimer() {
        var state = Self.handsFreeState(limit: .minutes2)
        #expect(
            reduce(&state, .timer(.handsFreeSecond)) == [
                .startTimer(.handsFreeSecond, .seconds(1))
            ]
        )
    }

    @Test
    func reachingTheLimitStopsCaptureAndTheClock() {
        var state = Self.handsFreeState(limit: .seconds30)
        var effects: [Effect] = []
        for _ in 0..<30 {
            effects = reduce(&state, .timer(.handsFreeSecond))
        }
        #expect(effects.contains(.stopCapture(Fixture.first)))
        #expect(effects.contains(.cancelTimer(.handsFreeSecond)))
        #expect(!effects.contains(.startTimer(.handsFreeSecond, .seconds(1))))
    }

    @Test
    func heardSpeechResetsTheSilenceCountdown() {
        var state = Self.handsFreeState(limit: .seconds30)
        for _ in 0..<25 {
            _ = reduce(&state, .timer(.handsFreeSecond))
        }
        _ = reduce(&state, Fixture.input(.segment(Fixture.segment(0))))
        _ = reduce(&state, .timer(.handsFreeSecond))
        #expect(state.hud == .handsFree(elapsed: .seconds(26), countdown: nil))
    }
}
