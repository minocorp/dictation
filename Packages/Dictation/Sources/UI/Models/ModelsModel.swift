public import Core
import Foundation
public import Observation

@MainActor
@Observable
public final class ModelsModel {
    public let downloads: ModelDownloads

    @ObservationIgnored
    private let settings: SettingsModel
    @ObservationIgnored
    private let library: any ModelLibrary
    @ObservationIgnored
    private let actions: ModelActions

    public init(
        settings: SettingsModel,
        downloads: ModelDownloads,
        library: any ModelLibrary,
        actions: ModelActions,
    ) {
        self.settings = settings
        self.downloads = downloads
        self.library = library
        self.actions = actions
    }

    func entries(_ stage: ModelStage) -> [ModelEntry] {
        library.entries(stage: stage)
    }

    func selected(_ stage: ModelStage) -> ModelEntry {
        let recommended = library.recommended()
        let choice =
            switch stage {
            case .speech: settings.preferences.speechModel
            case .cleanup: settings.preferences.cleanupModel
            }
        let fallback = stage == .speech ? recommended.speech : recommended.cleanup
        switch choice {
        case .recommended:
            return fallback
        case .model(let id):
            return entries(stage).first { $0.id == id } ?? fallback
        }
    }

    func isRecommended(_ entry: ModelEntry) -> Bool {
        let recommended = library.recommended()
        return entry.id == recommended.speech.id || entry.id == recommended.cleanup.id
    }

    func select(_ entry: ModelEntry) {
        switch entry.stage {
        case .speech: settings.preferences.speechModel = .model(id: entry.id)
        case .cleanup: settings.preferences.cleanupModel = .model(id: entry.id)
        }
        guard entry.isDownloadable else { return }
        switch downloads.state(of: entry) {
        case .notDownloaded, .failed: downloads.download(entry)
        case .waitingForApproval, .downloading, .ready: break
        }
    }

    func deleteEverything() async {
        await actions.deleteEverything()
        await downloads.refresh()
    }
}
