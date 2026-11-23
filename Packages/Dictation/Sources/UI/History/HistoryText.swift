import Core
import SwiftUI

internal struct HistoryText: View {
    let item: HistoryItem
    let isExpanded: Bool

    private var text: String {
        item.finalText.isEmpty ? item.rawText : item.finalText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let instruction = item.instruction {
                Text(verbatim: instruction)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Text(verbatim: text)
                .lineLimit(isExpanded ? nil : 2)
                .textSelection(.enabled)
        }
    }
}
