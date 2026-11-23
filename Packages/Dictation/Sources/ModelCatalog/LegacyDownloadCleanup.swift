import Foundation

public enum LegacyDownloadCleanup {
    private static let sessionIdentifiers = [
        "dictation.models.download.constrained",
        "dictation.models.download.unconstrained",
    ]
    private static let temporaryFilePrefix = "CFNetworkDownload_"

    public static func run() async {
        for identifier in sessionIdentifiers {
            await cancelTasks(ofSessionNamed: identifier)
        }
        removeLeftoverTemporaryFiles(in: FileManager.default.temporaryDirectory)
    }

    static func removeLeftoverTemporaryFiles(in directory: URL) {
        let names =
            (try? FileManager.default.contentsOfDirectory(
                atPath: directory.path(percentEncoded: false)
            )) ?? []
        for name in names where name.hasPrefix(temporaryFilePrefix) {
            try? FileManager.default.removeItem(at: directory.appending(path: name))
        }
    }

    private static func cancelTasks(ofSessionNamed identifier: String) async {
        let session = URLSession(
            configuration: .background(withIdentifier: identifier),
            delegate: nil,
            delegateQueue: nil,
        )
        for task in await session.allTasks {
            task.cancel()
        }
        session.invalidateAndCancel()
    }
}
