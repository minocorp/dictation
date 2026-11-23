import SwiftUI

internal struct LevelMeterView: View {
    private static let segmentCount = 24

    let level: Float

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<Self.segmentCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(isLit(index) ? Color.green : Color.primary.opacity(0.12))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityHidden(true)
    }

    private func isLit(_ index: Int) -> Bool {
        Float(index) < level * Float(Self.segmentCount)
    }
}
