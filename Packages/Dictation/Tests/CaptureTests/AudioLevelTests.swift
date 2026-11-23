@testable import Capture
import Testing

internal struct AudioLevelTests {
    @Test
    func silenceIsZero() {
        #expect(AudioLevel.normalized([0, 0, 0]) == 0)
        #expect(AudioLevel.normalized([]) == 0)
    }

    @Test
    func fullScaleIsOne() {
        #expect(AudioLevel.normalized([1, -1, 1, -1]) == 1)
    }

    @Test
    func minusThirtyDecibelsIsHalf() {
        let amplitude: Float = 0.0316228
        #expect(abs(AudioLevel.normalized([amplitude, -amplitude]) - 0.5) < 0.01)
    }

    @Test
    func clipsAboveFullScale() {
        #expect(AudioLevel.normalized([4, 4]) == 1)
    }
}
