import ApplicationServices
import Core
@testable import Hotkeys
import Synchronization
import Testing

internal struct TapContextTests {
    private let context: TapContext
    private let stream: AsyncStream<RawKeyEvent>
    private let continuation: AsyncStream<RawKeyEvent>.Continuation

    init() {
        let made = AsyncStream.makeStream(of: RawKeyEvent.self)
        stream = made.stream
        continuation = made.continuation
        context = TapContext(continuation: made.continuation)
    }

    private func setPolicy(swallowsEscape: Bool = false) {
        let policy = TapPolicy(
            dictateKey: .fn,
            pasteLast: .pasteLastDefault,
            swallowsEscape: swallowsEscape,
        )
        context.policy.withLock { $0 = policy }
    }

    private func yielded() async -> [RawKeyEvent] {
        continuation.finish()
        var events: [RawKeyEvent] = []
        for await event in stream { events.append(event) }
        return events
    }

    private func flagsChanged(_ keyCode: UInt16, isDown: Bool) -> TapInput {
        TapInput(
            kind: .flagsChanged,
            keyCode: keyCode,
            flags: isDown ? .maskSecondaryFn : [],
            mouseButton: 0,
            isRepeat: false,
        )
    }

    private func key(
        _ kind: TapInput.Kind,
        _ code: UInt16,
        flags: CGEventFlags = [],
        isRepeat: Bool = false,
    ) -> TapInput {
        TapInput(kind: kind, keyCode: code, flags: flags, mouseButton: 0, isRepeat: isRepeat)
    }

    @Test
    func dictateKeyPressAndReleaseAreSwallowedAndForwarded() async {
        setPolicy()
        #expect(context.process(flagsChanged(63, isDown: true)))
        #expect(context.process(flagsChanged(63, isDown: false)))
        #expect(await yielded() == [.fnDown, .fnUp])
    }

    @Test
    func releaseOfAPassedPressIsPassed() {
        setPolicy()
        #expect(!context.process(key(.keyDown, 96, flags: .maskCommand)))
        #expect(!context.process(key(.keyUp, 96)))
    }

    @Test
    func repeatedSwallowedPressIsForwardedOnce() async {
        setPolicy()
        #expect(context.process(flagsChanged(63, isDown: true)))
        #expect(context.process(key(.keyDown, 63, flags: .maskSecondaryFn, isRepeat: true)))
        #expect(await yielded() == [.fnDown])
    }

    @Test(arguments: [(false, false), (true, true)])
    func escapeIsSwallowedOnlyWhileLive(swallowsEscape: Bool, expected: Bool) {
        setPolicy(swallowsEscape: swallowsEscape)
        #expect(context.process(key(.keyDown, 53)) == expected)
        #expect(context.process(key(.keyUp, 53)) == expected)
    }

    @Test
    func irrelevantKeysAreNeitherForwardedNorSwallowed() async {
        setPolicy()
        #expect(!context.process(key(.keyDown, 0)))
        #expect(await yielded().isEmpty)
    }

    @Test
    func capturingForwardsEveryKeyAndSwallowsItsRelease() async {
        setPolicy()
        context.isCapturing.withLock { $0 = true }
        #expect(context.process(key(.keyDown, 0)))
        #expect(context.process(key(.keyDown, 0, isRepeat: true)))
        #expect(context.process(key(.keyUp, 0)))
        #expect(await yielded().map(\.phase) == [.pressed, .released])
    }

    @Test
    func capturingSwallowsFnButPassesSharedModifiers() async {
        setPolicy()
        context.isCapturing.withLock { $0 = true }
        #expect(context.process(flagsChanged(63, isDown: true)))
        #expect(context.process(flagsChanged(63, isDown: false)))
        let command = TapInput(
            kind: .flagsChanged,
            keyCode: 55,
            flags: .maskCommand,
            mouseButton: 0,
            isRepeat: false,
        )
        #expect(!context.process(command))
        #expect(await yielded().count == 3)
    }

    @Test
    func capturingSwallowsMouseButtons() async {
        setPolicy()
        context.isCapturing.withLock { $0 = true }
        let down = TapInput(
            kind: .mouseDown,
            keyCode: 0,
            flags: [],
            mouseButton: 3,
            isRepeat: false,
        )
        let up = TapInput(kind: .mouseUp, keyCode: 0, flags: [], mouseButton: 3, isRepeat: false)
        #expect(context.process(down))
        #expect(context.process(up))
        #expect(await yielded() == [.mouseDown, .mouseUp])
    }

    @Test
    func releaseAfterCapturingEndsIsStillSwallowed() async {
        setPolicy()
        context.isCapturing.withLock { $0 = true }
        #expect(context.process(key(.keyDown, 0)))
        context.isCapturing.withLock { $0 = false }
        #expect(context.process(key(.keyUp, 0)))
        #expect(!context.process(key(.keyDown, 0)))
    }

    @Test
    func shortcutKeyWhileDictateModifierIsHeldIsForwardedAndPassed() async {
        let policy = TapPolicy(
            dictateKey: KeyBinding(trigger: .key(code: 55), modifiers: []),
            pasteLast: .pasteLastDefault,
            swallowsEscape: false,
        )
        context.policy.withLock { $0 = policy }
        let command = TapInput(
            kind: .flagsChanged,
            keyCode: 55,
            flags: .maskCommand,
            mouseButton: 0,
            isRepeat: false,
        )
        #expect(!context.process(command))
        #expect(!context.process(key(.keyDown, 8, flags: .maskCommand)))
        #expect(!context.process(key(.keyUp, 8, flags: .maskCommand)))
        let events = await yielded()
        #expect(events.map(\.trigger) == [.key(code: 55), .key(code: 8)])
    }

    @Test
    func withoutPolicyEverythingIsForwardedAndNothingSwallowed() async {
        #expect(!context.process(key(.keyDown, 0)))
        #expect(!context.process(flagsChanged(63, isDown: true)))
        #expect(await yielded().count == 2)
    }
}
