import Core
import SwiftUI

internal struct HistoryRow: View {
    let model: HistoryModel
    let item: HistoryItem

    private var isExpanded: Bool { model.expanded == item.id }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            HistoryAppIcon(image: model.icon(for: item.appBundleID))
            VStack(alignment: .leading, spacing: 8) {
                HistoryText(item: item, isExpanded: isExpanded)
                if model.shownOriginals.contains(item.id) {
                    HistoryOriginalBox(item: item)
                }
                if isExpanded {
                    HistoryActionBar(model: model, item: item)
                }
            }
            Spacer(minLength: 12)
            HistoryMeta(item: item)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { model.toggleExpanded(item) }
        .accessibilityElement(children: .contain)
    }
}
