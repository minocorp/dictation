import Core
import SwiftUI

internal struct HistoryText: View {
    let item: HistoryItem
    let isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let instruction = item.instruction {
                Text(verbatim: instruction)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Text(verbatim: item.displayText)
                .lineLimit(isExpanded ? nil : 2)
                .textSelection(.enabled)
        }
    }
}
