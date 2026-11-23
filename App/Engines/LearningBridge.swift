import Core
import Foundation
import Learning
import Session
import Synchronization

internal final class LearningBridge: LearningObserver {
    private let learner: CorrectionLearner
    private let isEnabled: @Sendable () -> Bool
    private let running = Mutex<[UUID: Task<Void, Never>]>([:])

    init(learner: CorrectionLearner, isEnabled: @escaping @Sendable () -> Bool) {
        self.learner = learner
        self.isEnabled = isEnabled
    }

    func observe(inserted text: String, into focus: FocusSnapshot) {
        guard isEnabled() else { return }
        let identifier = UUID()
        let learner = learner
        let task = Task { [weak self] in
            await learner.observe(inserted: text, into: focus.target, focus: focus)
            self?.running.withLock { $0[identifier] = nil }
        }
        running.withLock { $0[identifier] = task }
    }
}
