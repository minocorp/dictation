import Foundation

internal enum AudioLevel {
    static let floorDecibels: Float = -60

    static func normalized(_ samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0 }
        let meanSquare = samples.reduce(0) { $0 + $1 * $1 } / Float(samples.count)
        let decibels = 10 * log10(max(meanSquare, .leastNormalMagnitude))
        return min(max((decibels - floorDecibels) / -floorDecibels, 0), 1)
    }
}
