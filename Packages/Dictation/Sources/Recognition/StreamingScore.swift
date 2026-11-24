import Core
import FluidAudio
import Foundation
import os

internal actor StreamingScore {
    private static let logger = Logger(dictationCategory: "Speech")

    private let manager: VadManager
    private var state: VadStreamState

    init(manager: VadManager) {
        self.manager = manager
        state = VadStreamState.initial()
    }

    func probability(of frame: [Float]) async -> Float {
        do {
            let result = try await manager.processStreamingChunk(frame, state: state)
            state = result.state
            return result.probability
        } catch {
            Self.logger.error(
                "silero frame failed: \(error.localizedDescription, privacy: .public)"
            )
            return 1
        }
    }
}
