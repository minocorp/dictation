import SwiftUI

internal struct HUDLevelBars: View {
    let heights: [CGFloat]
    let style: Color

    var body: some View {
        HStack(spacing: HUDMetrics.barSpacing) {
            ForEach(heights.indices, id: \.self) { index in
                Capsule()
                    .fill(style)
                    .frame(width: HUDMetrics.barWidth, height: heights[index])
            }
        }
        .frame(height: HUDMetrics.maximumBarHeight)
        .accessibilityHidden(true)
    }
}
