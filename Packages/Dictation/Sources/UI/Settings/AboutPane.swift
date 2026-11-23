import SwiftUI

internal struct AboutPane: View {
    @Bindable
    var model: AboutModel

    var body: some View {
        Form {
            Section {
                LabeledContent(UIString.aboutVersion) {
                    Text(verbatim: model.version)
                }
                Button(UIString.aboutLicenses) { model.isShowingLicenses = true }
                Button(UIString.aboutExportDiagnostics) {
                    Task { await model.beginExport() }
                }
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $model.isShowingLicenses) {
            LicensesSheet(notices: model.notices) { model.isShowingLicenses = false }
        }
        .sheet(isPresented: exportBinding) {
            ExportDiagnosticsSheet(model: model)
        }
    }

    private var exportBinding: Binding<Bool> {
        Binding(get: { model.isShowingExport }, set: { if !$0 { model.dismissExport() } })
    }
}
