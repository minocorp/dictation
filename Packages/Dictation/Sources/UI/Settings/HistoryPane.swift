import Core
import SwiftUI

internal struct HistoryPane: View {
    @Bindable
    var model: SettingsModel
    @State
    private var isConfirmingClear = false

    var body: some View {
        Form {
            Section {
                Picker(UIString.historyRetention, selection: $model.preferences.historyRetention) {
                    ForEach(HistoryRetention.allCases, id: \.self) { retention in
                        Text(retention.label).tag(retention)
                    }
                }
            }
            Section {
                Button(UIString.historyClear, role: .destructive) { isConfirmingClear = true }
                    .confirmationDialog(
                        Text(UIString.historyClearTitle),
                        isPresented: $isConfirmingClear,
                    ) {
                        Button(UIString.historyClearConfirm, role: .destructive) {
                            Task { await model.clearHistory() }
                        }
                        Button(UIString.historyClearCancel, role: .cancel) {}
                    }
            }
        }
        .formStyle(.grouped)
    }
}
