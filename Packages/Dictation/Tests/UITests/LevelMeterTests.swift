import Testing
@testable import UI

internal struct LevelMeterTests {
    @Test
    func restsAtMinimumHeight() {
        #expect(LevelMeter().barHeights == LevelMeter.restingHeights)
    }

    @Test
    func attackIsFasterThanRelease() {
        var rising = LevelMeter()
        rising.advance(toward: 1, elapsed: 0.04, smoothing: true)
        var falling = LevelMeter()
        falling.advance(toward: 1, elapsed: 10, smoothing: true)
        falling.advance(toward: 0, elapsed: 0.04, smoothing: true)
        #expect(rising.level > 1 - falling.level)
    }

    @Test
    func withoutSmoothingTheLevelFollowsTheInput() {
        var meter = LevelMeter()
        meter.advance(toward: 0.7, elapsed: 0.001, smoothing: false)
        #expect(meter.level == 0.7)
    }

    @Test
    func inputIsClampedToTheUnitRange() {
        var meter = LevelMeter()
        meter.advance(toward: 4, elapsed: 1, smoothing: false)
        #expect(meter.level == 1)
    }

    @Test
    func fullLevelDrivesTheMiddleBarToMaximumHeight() {
        var meter = LevelMeter()
        meter.advance(toward: 1, elapsed: 1, smoothing: false)
        #expect(meter.barHeights[4] == HUDMetrics.maximumBarHeight)
        #expect(meter.barHeights[0] < meter.barHeights[4])
    }

    @Test
    func resetReturnsToRest() {
        var meter = LevelMeter()
        meter.advance(toward: 1, elapsed: 1, smoothing: false)
        meter.reset()
        #expect(meter.barHeights == LevelMeter.restingHeights)
    }
}
