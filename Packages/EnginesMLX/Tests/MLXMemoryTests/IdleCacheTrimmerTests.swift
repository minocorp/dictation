import Clocks
import CoreTesting
@testable import MLXMemory
import Testing

internal struct IdleCacheTrimmerTests {
    private let clock = CoreTesting.TestClock()
    private let clears = ClearCounter()

    private func makeTrimmer() -> IdleCacheTrimmer {
        let clears = clears
        return IdleCacheTrimmer(clock: clock, clear: { clears.increment() })
    }

    private func waitForClears(_ count: Int) async {
        while clears.total < count { await Task.yield() }
    }

    @Test
    func clearsTheCacheOnceAfterTwentyIdleSeconds() async {
        let trimmer = makeTrimmer()
        trimmer.end()
        await clock.advance(by: .seconds(19))
        #expect(clears.total == 0)
        await clock.advance(by: .seconds(1))
        await waitForClears(1)
        #expect(clears.total == 1)
    }

    @Test
    func newWorkCancelsThePendingClear() async {
        let trimmer = makeTrimmer()
        trimmer.end()
        await clock.advance(by: .seconds(10))
        trimmer.begin()
        await clock.advance(by: .seconds(60))
        #expect(clears.total == 0)
    }

    @Test
    func eachFinishedJobRestartsTheIdleWindow() async {
        let trimmer = makeTrimmer()
        trimmer.end()
        await clock.advance(by: .seconds(15))
        trimmer.begin()
        trimmer.end()
        await clock.advance(by: .seconds(15))
        #expect(clears.total == 0)
        await clock.advance(by: .seconds(5))
        await waitForClears(1)
    }
}
