import Core
@testable import Session
import Testing

internal struct ReducerCase: Sendable, CustomTestStringConvertible {
    let name: String
    let setup: [Event]
    let event: Event
    let effects: [Effect]
    let hud: HUDState
    let isLive: Bool

    var testDescription: String { name }

    init(
        _ name: String,
        setup: [Event] = [],
        event: Event,
        effects: [Effect],
        hud: HUDState,
        isLive: Bool,
    ) {
        self.name = name
        self.setup = setup
        self.event = event
        self.effects = effects
        self.hud = hud
        self.isLive = isLive
    }

    func check() {
        let before = Fixture.play(setup).state
        let result = Fixture.play([event], from: before)
        #expect(result.effects == effects)
        #expect(result.state.hud == hud)
        #expect(result.state.isLive == isLive)
    }
}
