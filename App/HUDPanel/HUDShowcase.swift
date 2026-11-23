#if DEBUG
import Core
import Foundation
import Observation

@MainActor
@Observable
internal final class HUDShowcase {
    private static let argument = "--hud-showcase"
    private static let dwell = Duration.seconds(3)
    private static let states: [HUDState] = [
        .listening,
        .handsFree(elapsed: .seconds(42), countdown: nil),
        .handsFree(elapsed: .seconds(111), countdown: .seconds(9)),
        .editing,
        .processing,
        .copied,
        .canceled,
        .saved,
        .noSpeech,
        .problem(.microphoneDenied),
        .problem(.passwordField),
    ]

    static var isRequested: Bool { CommandLine.arguments.contains(argument) }

    private(set) var state = HUDState.hidden
    @ObservationIgnored
    private var task: Task<Void, Never>?

    isolated deinit {
        task?.cancel()
    }

    static func levels() -> AsyncStream<Float> {
        AsyncStream { continuation in
            let task = Task {
                var phase = 0.0
                while !Task.isCancelled {
                    phase += 0.35
                    continuation.yield(Float(0.55 + 0.4 * sin(phase) * sin(phase * 0.37)))
                    try? await ContinuousClock().sleep(for: .milliseconds(33))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func start() {
        task = Task { [weak self] in
            try? await ContinuousClock().sleep(for: .seconds(2))
            for state in Self.states {
                self?.state = state
                try? await ContinuousClock().sleep(for: Self.dwell)
                self?.state = .hidden
                try? await ContinuousClock().sleep(for: .milliseconds(400))
            }
        }
    }
}
#endif
