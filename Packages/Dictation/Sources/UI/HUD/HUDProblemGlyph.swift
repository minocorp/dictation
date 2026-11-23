import AppKit
import SwiftUI

internal struct HUDProblemGlyph: View {
    @Environment(\.colorScheme)
    private var colorScheme
    @Environment(\.colorSchemeContrast)
    private var contrast

    private var fill: Color {
        if contrast == .increased { return .primary }
        return colorScheme == .dark ? .yellow : Color.orange.mix(with: .black, by: 0.25)
    }

    var body: some View {
        Circle()
            .fill(fill)
            .frame(width: 16, height: 16)
            .overlay {
                Text(verbatim: "!")
                    .font(HUDMetrics.problemGlyph)
                    .foregroundStyle(
                        colorScheme == .dark || contrast == .increased
                            ? Color(nsColor: .windowBackgroundColor) : .white
                    )
            }
            .accessibilityHidden(true)
    }
}
