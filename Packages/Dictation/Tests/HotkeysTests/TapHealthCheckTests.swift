import Clocks
@testable import Hotkeys
import Testing

internal struct TapHealthCheckTests {
    private static let healthy = TapHealth(isTapEnabled: true, isAccessibilityTrusted: true)
    private static let tapDisabled = TapHealth(isTapEnabled: false, isAccessibilityTrusted: true)
    private static let untrusted = TapHealth(isTapEnabled: false, isAccessibilityTrusted: false)

    @Test
    func reportsInitialStatusThenOnlyChangesEveryInterval() async {
        let clock = Clocks.TestClock<Duration>()
        let probe = ScriptedTapProbe(Self.healthy)
        let check = TapHealthCheck(probe: probe, clock: clock, interval: .seconds(2))
        let (stream, continuation) = AsyncStream.makeStream(of: TapHealth.self)
        let task = Task { await check.run(into: continuation) }
        var iterator = stream.makeAsyncIterator()

        #expect(await iterator.next() == Self.healthy)

        await clock.advance(by: .seconds(1))
        probe.set(Self.tapDisabled)
        await clock.advance(by: .seconds(1))
        #expect(await iterator.next() == Self.tapDisabled)
        #expect(probe.readCount == 2)

        await clock.advance(by: .seconds(2))
        probe.set(Self.untrusted)
        await clock.advance(by: .seconds(2))
        #expect(await iterator.next() == Self.untrusted)

        task.cancel()
        await task.value
    }

    @Test
    func stopsWhenCancelled() async {
        let clock = Clocks.TestClock<Duration>()
        let probe = ScriptedTapProbe(Self.healthy)
        let check = TapHealthCheck(probe: probe, clock: clock, interval: .seconds(2))
        let (stream, continuation) = AsyncStream.makeStream(of: TapHealth.self)
        let task = Task { await check.run(into: continuation) }
        var iterator = stream.makeAsyncIterator()
        _ = await iterator.next()
        task.cancel()
        await task.value
        #expect(probe.readCount == 1)
    }
}
