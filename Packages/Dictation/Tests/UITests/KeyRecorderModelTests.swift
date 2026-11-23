import Core
import Testing
@testable import UI

@MainActor
internal struct KeyRecorderModelTests {
    private final class Box {
        var binding = KeyBinding.fn
    }

    private let box = Box()

    private func makeModel(
        kind: KeyRecorderKind = .dictateKey,
        events: AsyncStream<RawKeyEvent> = AsyncStream { $0.finish() },
    ) -> KeyRecorderModel {
        KeyRecorderModel(
            kind: kind,
            defaultBinding: .fn,
            binding: { [box] in box.binding },
            capture: { events },
            commit: { [box] in box.binding = $0 },
        )
    }

    @Test
    func acceptedKeyIsCommittedAndConfirmed() {
        let model = makeModel()
        let consumed = model.receive(UIFixtures.event(code: 61, modifiers: [.option]))
        #expect(consumed)
        #expect(box.binding == .rightOption)
        #expect(model.confirmations == 1)
    }

    @Test
    func ignoredEventsAreNotConsumed() {
        let model = makeModel(kind: .shortcut)
        #expect(!model.receive(UIFixtures.event(code: 9)))
        #expect(model.confirmations == 0)
    }

    @Test
    func escapeEndsRecordingWithoutChangingTheBinding() {
        let model = makeModel()
        #expect(model.receive(UIFixtures.event(code: 53)))
        #expect(box.binding == .fn)
    }

    @Test
    func resetRestoresTheDefault() {
        box.binding = .rightOption
        let model = makeModel()
        #expect(!model.isDefault)
        model.reset()
        #expect(box.binding == .fn)
    }

    @Test
    func recordingEndsAfterTheCapturedKey() async {
        let (stream, continuation) = AsyncStream.makeStream(of: RawKeyEvent.self)
        let model = makeModel(events: stream)
        model.begin()
        #expect(model.isRecording)
        continuation.yield(UIFixtures.event(code: 61, modifiers: [.option]))
        while model.isRecording { await Task.yield() }
        #expect(box.binding == .rightOption)
    }

    @Test
    func cancelStopsRecording() {
        let (stream, _) = AsyncStream.makeStream(of: RawKeyEvent.self)
        let model = makeModel(events: stream)
        model.begin()
        model.cancel()
        #expect(!model.isRecording)
    }
}
