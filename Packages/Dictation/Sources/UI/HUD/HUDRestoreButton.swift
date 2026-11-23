import SwiftUI

internal struct HUDRestoreButton: View {
    let action: () -> Void

    @Environment(\.colorSchemeContrast)
    private var contrast
    @State
    private var isHovering = false

    var body: some View {
        Button(action: action) {
            Label {
                Text(UIString.hudRestore)
            } icon: {
                Image(systemName: HUDMetrics.restoreSymbol)
                    .foregroundStyle(contrast == .increased ? Color.primary : Color.accentColor)
            }
            .font(HUDMetrics.text)
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 8)
            .frame(height: HUDMetrics.controlSize)
            .background(Color.primary.opacity(isHovering ? 0.12 : 0.07), in: Capsule())
            .overlay {
                if contrast == .increased {
                    Capsule().strokeBorder(Color.primary, lineWidth: HUDMetrics.borderWidth)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
