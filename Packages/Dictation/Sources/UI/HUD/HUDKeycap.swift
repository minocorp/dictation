import SwiftUI

internal struct HUDKeycap: View {
    let text: String

    @Environment(\.colorScheme)
    private var colorScheme

    var body: some View {
        Text(verbatim: text)
            .font(HUDMetrics.keycap)
            .padding(.horizontal, 6)
            .frame(height: 20)
            .background(
                Color.primary.opacity(
                    colorScheme == .dark
                        ? HUDMetrics.keycapOpacityDark : HUDMetrics.keycapOpacityLight
                ),
                in: RoundedRectangle(cornerRadius: 5),
            )
    }
}
