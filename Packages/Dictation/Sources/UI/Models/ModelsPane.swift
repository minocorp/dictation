import Core
import SwiftUI

internal struct ModelsPane: View {
    let model: ModelsModel
    @State
    private var isConfirmingDelete = false

    var body: some View {
        Form {
            Section {
                ModelPickerRow(model: model, stage: .speech, title: UIString.modelsSpeech)
                ModelPickerRow(model: model, stage: .cleanup, title: UIString.modelsCleanup)
            }
            Section {
                Button(UIString.modelsDeleteAll, role: .destructive) { isConfirmingDelete = true }
                    .confirmationDialog(
                        Text(UIString.modelsDeleteAllTitle),
                        isPresented: $isConfirmingDelete,
                    ) {
                        Button(UIString.modelsDeleteAllConfirm, role: .destructive) {
                            Task { await model.deleteEverything() }
                        }
                        Button(UIString.modelsDeleteAllCancel, role: .cancel) {}
                    }
            }
        }
        .formStyle(.grouped)
        .task { await model.downloads.refresh() }
    }
}
