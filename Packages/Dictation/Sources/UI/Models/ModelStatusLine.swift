import Core
import SwiftUI

internal struct ModelStatusLine: View {
    let model: ModelsModel
    let entry: ModelEntry

    var body: some View {
        HStack(spacing: 8) {
            Text(verbatim: model.detail(entry))
                .foregroundStyle(.secondary)
            Spacer()
            status
        }
        .font(.callout)
    }

    @ViewBuilder
    private var status: some View {
        let downloads = model.downloads
        switch downloads.state(of: entry) {
        case .ready:
            if entry.isDownloadable {
                Button(UIString.commonDelete, role: .destructive) { downloads.delete(entry) }
                    .buttonStyle(.borderless)
            }
        case .notDownloaded:
            Button(UIString.modelsDownload) { downloads.download(entry) }
        case .waitingForApproval:
            Text(UIString.modelsStateWaiting)
                .foregroundStyle(.secondary)
            Button(UIString.modelsAllowConstrained) { downloads.downloadAllowingConstrained(entry) }
        case .downloading(let received, let total):
            if downloads.verifying.contains(entry.id) {
                Text(UIString.modelsStateVerifying)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView(value: Double(received), total: Double(max(total, 1)))
                    .frame(width: 120)
            }
            Button(UIString.modelsCancelDownload) { downloads.cancel(entry) }
        case .failed(let error):
            Text(error.message)
                .foregroundStyle(.red)
            Button(UIString.modelsDownload) { downloads.download(entry) }
        }
    }
}
