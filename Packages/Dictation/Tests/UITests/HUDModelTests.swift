import Core
import Observation
import Testing
@testable import UI

@MainActor
internal struct HUDModelTests {
    @MainActor
    @Observable
    final class Source {
        var state = HUDState.hidden
    }

    @MainActor
    final class Recorder {
        var gestures: [Gesture] = []
        var fixes: [HUDFix] = []
        var announcements: [String] = []
    }

    private let source = Source()
    private let recorder = Recorder()

    private func makeModel() -> HUDModel {
        HUDModel(
            state: { [source] in source.state },
            levels: AsyncStream { $0.finish() },
            actions: HUDActions(
                perform: { [recorder] in recorder.gestures.append($0) },
                openFix: { [recorder] in recorder.fixes.append($0) },
                announce: { [recorder] in recorder.announcements.append($0) },
            ),
        )
    }

    @Test
    func presentingAStateKeepsItDisplayedAfterItHides() {
        let model = makeModel()
        source.state = .copied
        model.apply(.copied)
        model.apply(.hidden)
        #expect(!model.isPresented)
        #expect(model.displayed == .copied)
    }

    @Test
    func announcesAStateChangeOnce() {
        let model = makeModel()
        model.apply(.listening)
        model.apply(.listening)
        #expect(recorder.announcements == [UIString.string(UIString.hudListening)])
    }

    @Test
    func controlsForwardGestures() {
        let model = makeModel()
        model.stop()
        model.cancel()
        model.restore()
        #expect(recorder.gestures == [.stop, .cancel, .restore])
    }

    @Test
    func problemWithAFixOpensIt() {
        let model = makeModel()
        model.openFix(for: .accessibilityOff)
        model.openFix(for: .passwordField)
        #expect(recorder.fixes == [.openPermissionSettings(.accessibility)])
    }

    @Test
    func onlyControlStatesAcceptTheMouse() {
        let model = makeModel()
        let expectations: [(HUDState, Bool)] = [
            (.listening, false),
            (.handsFree(elapsed: .zero, countdown: nil), true),
            (.canceled, true),
            (.problem(.microphoneDenied), true),
            (.problem(.passwordField), false),
            (.copied, false),
        ]
        for (state, accepts) in expectations {
            source.state = state
            #expect(model.acceptsMouse == accepts)
        }
    }

    @Test
    func barsRiseWhileListeningAndRestOtherwise() {
        let model = makeModel()
        source.state = .listening
        model.apply(.listening)
        model.advanceMeter(toward: 1)
        #expect(model.barHeights != LevelMeter.restingHeights)
        source.state = .processing
        model.apply(.processing)
        #expect(model.barHeights == LevelMeter.restingHeights)
    }
}
