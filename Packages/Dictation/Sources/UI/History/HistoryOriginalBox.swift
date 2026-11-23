import Core
import SwiftUI

internal struct HistoryOriginalBox: View {
    let item: HistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(UIString.historyOriginal)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(verbatim: item.rawText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}
