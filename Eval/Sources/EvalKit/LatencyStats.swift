internal struct LatencyStats: Equatable {
    let samples: [Duration]

    var median: Duration { percentile(0.5) }
    var p95: Duration { percentile(0.95) }

    func percentile(_ fraction: Double) -> Duration {
        guard !samples.isEmpty else { return .zero }
        let sorted = samples.sorted()
        let rank = Int((fraction * Double(sorted.count)).rounded(.up)) - 1
        return sorted[min(max(rank, 0), sorted.count - 1)]
    }

    func fractionOver(_ limit: Duration) -> Double {
        guard !samples.isEmpty else { return 0 }
        return Double(samples.count { $0 > limit }) / Double(samples.count)
    }
}

extension Duration {
    internal var milliseconds: Double {
        let parts = components
        return Double(parts.seconds) * 1000 + Double(parts.attoseconds) / 1e15
    }
}
