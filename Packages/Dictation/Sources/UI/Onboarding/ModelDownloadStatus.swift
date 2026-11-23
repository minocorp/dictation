import Core
import SwiftUI

internal struct ModelDownloadStatus: View {
    let model: OnboardingModel

    var body: some View {
        switch model.downloadNote {
        case .none:
            EmptyView()
        case .downloading(let progress, let totalBytes):
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(UIString.obTryDownloading)
                    Text(Int64(totalBytes), format: .byteCount(style: .file))
                    Spacer()
                    Text(progress.fraction, format: .percent.precision(.fractionLength(0)))
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                ProgressView(value: progress.fraction)
            }
        case .waitingForApproval:
            HStack {
                Text(UIString.obTryWaiting)
                    .foregroundStyle(.secondary)
                Button(UIString.obTryAllowDownload, action: model.allowDownloads)
            }
        case .failed(let error):
            HStack {
                Text(error.message)
                    .foregroundStyle(.red)
                Button(UIString.obTryRetry, action: model.retryDownloads)
            }
            .font(.callout)
        case .ready:
            Text(UIString.obTryReady)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}
