import FluidAudio
import Foundation
import os

internal actor SileroModel {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "",
        category: "Speech",
    )

    private let modelDirectory: URL?
    private var manager: VadManager?

    init(modelDirectory: URL?) {
        self.modelDirectory = modelDirectory
    }

    func makeScorer() async -> FrameScorer? {
        guard let manager = await loadedManager() else { return nil }
        let stream = StreamingScore(manager: manager)
        return FrameScorer { frame in await stream.probability(of: frame) }
    }

    private func loadedManager() async -> VadManager? {
        if let manager { return manager }
        do {
            let loaded =
                if let modelDirectory {
                    try await VadManager(modelDirectory: modelDirectory)
                } else {
                    try await VadManager()
                }
            manager = loaded
            return loaded
        } catch {
            Self.logger.error("silero load failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
