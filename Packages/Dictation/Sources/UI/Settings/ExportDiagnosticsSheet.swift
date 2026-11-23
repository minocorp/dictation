import SwiftUI

internal struct ExportDiagnosticsSheet: View {
    let model: AboutModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(UIString.aboutExportTitle)
                .font(.headline)
            switch model.export {
            case .ready(let files):
                Text(UIString.aboutExportFiles)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(files, id: \.self) { name in
                        Text(verbatim: name)
                            .font(.system(.body, design: .monospaced))
                    }
                }
            case .failed:
                Text(UIString.aboutExportFailed)
                    .foregroundStyle(.red)
            case .idle:
                EmptyView()
            }
            HStack {
                Spacer()
                Button(UIString.aboutExportCancel, action: model.dismissExport)
                    .keyboardShortcut(.cancelAction)
                if case .ready = model.export {
                    Button(UIString.aboutExportSave, action: model.saveExport)
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(20)
        .frame(width: 380)
    }
}
