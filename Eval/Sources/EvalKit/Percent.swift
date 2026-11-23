import Foundation

internal enum Percent {
    static func text(_ fraction: Double) -> String {
        String(format: "%.1f%%", fraction * 100)
    }

    static func text(_ count: Int, of total: Int) -> String {
        guard total > 0 else { return "n/a" }
        return "\(text(Double(count) / Double(total))) (\(count)/\(total))"
    }
}
