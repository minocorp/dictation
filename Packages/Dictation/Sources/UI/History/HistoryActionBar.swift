import Core
import SwiftUI

internal struct HistoryActionBar: View {
    let model: HistoryModel
    let item: HistoryItem

    private var isShowingOriginal: Bool { model.shownOriginals.contains(item.id) }

    var body: some View {
        HStack(spacing: 6) {
            Button(UIString.historyCopy) { model.copy(item) }
            Button(isShowingOriginal ? UIString.historyHideOriginal : UIString.historyShowOriginal)
            {
                model.toggleOriginal(item)
            }
            Button(UIString.historyRetry) {
                Task { await model.retry(item) }
            }
            .disabled(!model.canRetry(item))
            Button(UIString.historyAddToDictionary) { model.dictionaryCandidate = item }
            Button(UIString.historyDelete, role: .destructive) {
                Task { await model.delete(item) }
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .buttonBorderShape(.capsule)
    }
}
