import Core
@testable import Hotkeys
import Testing

internal struct GestureRecognizerTests {
    private static let pasteLast = KeyBinding.pasteLastDefault

    @Test(
        arguments: HoldGestureCases.all + EscapeGestureCases.all + BindingGestureCases.all
            + ShortcutGestureCases.all
    )
    func stepsProduceExpectedGestures(testCase: GestureCase) {
        var state = GestureState(dictateKey: testCase.dictateKey, pasteLast: Self.pasteLast)
        let origin = ContinuousClock.now
        for step in testCase.steps {
            let gestures = GestureRecognizer.recognize(
                &state,
                step.event,
                at: origin.advanced(by: .milliseconds(step.atMs)),
            )
            #expect(gestures == step.expected, "at \(step.atMs) ms")
        }
    }

    @Test
    func resetDropsHandsFreeSoTheNextPressStartsAnew() {
        var state = GestureState(dictateKey: .fn, pasteLast: Self.pasteLast)
        let origin = ContinuousClock.now
        _ = GestureRecognizer.recognize(&state, .fnDown, at: origin)
        _ = GestureRecognizer.recognize(&state, .fnUp, at: origin.advanced(by: .milliseconds(100)))
        _ = GestureRecognizer.recognize(
            &state,
            .fnDown,
            at: origin.advanced(by: .milliseconds(200)),
        )
        _ = GestureRecognizer.recognize(&state, .fnUp, at: origin.advanced(by: .milliseconds(300)))
        state.reset()
        let gestures = GestureRecognizer.recognize(
            &state,
            .fnDown,
            at: origin.advanced(by: .seconds(10)),
        )
        #expect(gestures == [.pressBegan])
    }

    @Test
    func stateIsIdleOnlyBetweenGestures() {
        var state = GestureState(dictateKey: .fn, pasteLast: Self.pasteLast)
        #expect(state.isIdle)
        _ = GestureRecognizer.recognize(&state, .fnDown, at: .now)
        #expect(!state.isIdle)
        state.reset()
        #expect(state.isIdle)
    }
}
