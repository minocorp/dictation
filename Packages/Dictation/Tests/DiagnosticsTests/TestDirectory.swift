import Foundation

internal final class TestDirectory: Sendable {
    let url: URL

    init() {
        url = FileManager.default.temporaryDirectory
            .appending(
                path: "dictation-store-tests-\(UUID().uuidString)",
                directoryHint: .isDirectory,
            )
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
