@testable import EvalKit
import Testing

internal struct LatencyStatsTests {
    private let stats = LatencyStats(samples: (1...20).map { Duration.milliseconds($0 * 10) })

    @Test
    func medianAndTailUseNearestRank() {
        #expect(stats.median == .milliseconds(100))
        #expect(stats.p95 == .milliseconds(190))
    }

    @Test
    func fractionOverCountsStrictlyGreater() {
        #expect(stats.fractionOver(.milliseconds(150)) == 0.25)
    }

    @Test
    func emptySamplesGiveZero() {
        #expect(LatencyStats(samples: []).median == .zero)
        #expect(LatencyStats(samples: []).fractionOver(.zero) == 0)
    }
}
