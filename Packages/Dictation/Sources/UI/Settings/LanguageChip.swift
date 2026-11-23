import SwiftUI

internal struct LanguageChip: View {
    let name: String
    let remove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(verbatim: name)
            Button(action: remove) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(UIString.settingsRemoveLanguage(name)))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(.quaternary, in: Capsule())
    }
}
