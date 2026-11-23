import Core
import SwiftUI

internal struct HistoryMeta: View {
    let item: HistoryItem

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 4) {
                Text(verbatim: item.appName)
                Text(verbatim: "·")
                Text(item.date, format: .dateTime.hour().minute())
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                if item.kind == .edit {
                    badge(UIString.historyKindEdit)
                }
                if let status = item.status.label {
                    badge(status)
                }
            }
        }
    }

    private func badge(_ title: LocalizedStringResource) -> some View {
        Text(title)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(.quaternary, in: Capsule())
    }
}
