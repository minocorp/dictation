import Core
public import SwiftUI

public struct HistoryView: View {
    @Bindable
    var model: HistoryModel

    public init(model: HistoryModel) {
        self.model = model
    }

    public var body: some View {
        List {
            ForEach(model.sections) { section in
                Section {
                    ForEach(section.items, id: \.id) { item in
                        HistoryRow(model: model, item: item)
                    }
                } header: {
                    HistorySectionHeader(
                        title: section.title(now: model.now, calendar: .current)
                    )
                }
            }
        }
        .listStyle(.inset)
        .overlay { emptyState }
        .searchable(text: $model.query, prompt: Text(UIString.historySearch))
        .task(id: model.query) { await model.watch() }
        .sheet(isPresented: isAddingToDictionary) {
            if let item = model.dictionaryCandidate {
                AddToDictionarySheet(model: model.dictionary, item: item) {
                    model.dictionaryCandidate = nil
                }
            }
        }
        .frame(minWidth: 560, minHeight: 360)
    }

    @ViewBuilder
    private var emptyState: some View {
        if model.sections.isEmpty {
            if model.query.isEmpty {
                ContentUnavailableView {
                    Text(UIString.historyEmpty)
                }
            } else {
                ContentUnavailableView.search(text: model.query)
            }
        }
    }

    private var isAddingToDictionary: Binding<Bool> {
        Binding(
            get: { model.dictionaryCandidate != nil },
            set: { if !$0 { model.dictionaryCandidate = nil } },
        )
    }
}
