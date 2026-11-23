import Foundation

internal struct LevelMeter: Equatable {
    static let attack = 0.040
    static let release = 0.120
    static let restingHeights = [CGFloat](repeating: HUDMetrics.minimumBarHeight, count: 9)

    private(set) var level: Float = 0

    var barHeights: [CGFloat] {
        HUDMetrics.barEnvelope.map { envelope in
            let span = HUDMetrics.maximumBarHeight - HUDMetrics.minimumBarHeight
            return HUDMetrics.minimumBarHeight + span * CGFloat(level * envelope)
        }
    }

    mutating func advance(toward target: Float, elapsed: Double, smoothing: Bool) {
        let clamped = min(max(target, 0), 1)
        guard smoothing else {
            level = clamped
            return
        }
        let timeConstant = clamped > level ? Self.attack : Self.release
        level += (clamped - level) * Float(1 - exp(-elapsed / timeConstant))
    }

    mutating func reset() {
        level = 0
    }
}
