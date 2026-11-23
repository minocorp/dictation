import Core
import Foundation

extension ModelsModel {
    func optionTitle(_ entry: ModelEntry) -> String {
        var parts = [entry.localizedName]
        if entry.isDownloadable {
            parts.append(Int64(entry.downloadBytes).formatted(.byteCount(style: .file)))
            parts.append(UIString.string(stateName(of: entry)))
        }
        if isRecommended(entry) {
            parts.append(UIString.string(UIString.modelsRecommended))
        }
        return parts.joined(separator: " · ")
    }

    func detail(_ entry: ModelEntry) -> String {
        guard entry.isDownloadable else { return UIString.string(UIString.modelsBuiltIn) }
        return UIString.string(UIString.modelsLicense(entry.license))
    }

    private func stateName(of entry: ModelEntry) -> LocalizedStringResource {
        switch downloads.state(of: entry) {
        case .ready: UIString.modelsStateReady
        case .notDownloaded: UIString.modelsStateNotDownloaded
        case .waitingForApproval: UIString.modelsStateWaiting
        case .downloading: UIString.modelsStateDownloading
        case .failed: UIString.modelsStateFailed
        }
    }
}
