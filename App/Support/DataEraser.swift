import Core
import ModelCatalog

internal enum DataEraser {
    static func eraseAll(library: ManifestModelLibrary, stores: AppStores) async {
        for stage in ModelStage.allCases {
            for entry in library.entries(stage: stage) where entry.isDownloadable {
                do {
                    try await library.deleteAfterTransferStops(entry)
                } catch {
                    AppLog.failure("delete model", error)
                }
            }
        }
        do {
            try await stores.history.deleteAll()
            for word in try await stores.words.all() {
                try await stores.words.remove(text: word.text)
            }
        } catch {
            AppLog.failure("erase user data", error)
        }
    }

    static func installedEntries(library: ManifestModelLibrary) async -> [ModelEntry] {
        var installed: [ModelEntry] = []
        for stage in ModelStage.allCases {
            for entry in library.entries(stage: stage) where entry.isDownloadable {
                if await library.state(of: entry) == .ready { installed.append(entry) }
            }
        }
        return installed
    }
}
