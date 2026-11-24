import Core
import Learning
import Session

internal final class LearningBridge: LearningObserver {
    private let learner: CorrectionLearner
    private let isEnabled: @Sendable () -> Bool

    init(learner: CorrectionLearner, isEnabled: @escaping @Sendable () -> Bool) {
        self.learner = learner
        self.isEnabled = isEnabled
    }

    func observe(inserted text: String, into focus: FocusSnapshot) {
        guard isEnabled() else { return }
        let learner = learner
        Task {
            await learner.observe(inserted: text, into: focus.target, focus: focus)
        }
    }
}
