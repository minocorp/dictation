import Foundation

internal struct AppPaths: Sendable {
    let root: URL
    let data: URL
    let audio: URL
    let models: URL
    let logs: URL

    static func make() -> AppPaths {
        let support = URL.applicationSupportDirectory
        let root = support.appending(
            path: Bundle.main.bundleIdentifier ?? "app.dictation",
            directoryHint: .isDirectory,
        )
        let data = root.appending(path: "Data", directoryHint: .isDirectory)
        return AppPaths(
            root: root,
            data: data,
            audio: data.appending(path: "Audio", directoryHint: .isDirectory),
            models: root.appending(path: "Models", directoryHint: .isDirectory),
            logs: root.appending(path: "Logs", directoryHint: .isDirectory),
        )
    }

    func prepare() {
        for directory in [root, models, logs] {
            try? FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
            )
        }
    }
}
