import SwiftUI

internal struct HUDControlButton: View {
    let systemImage: String
    let label: LocalizedStringResource
    let action: () -> Void

    @State
    private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(HUDMetrics.controlGlyph)
                .frame(width: HUDMetrics.controlSize, height: HUDMetrics.controlSize)
                .background(Color.primary.opacity(isHovering ? 0.12 : 0.07), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel(Text(label))
    }
}
