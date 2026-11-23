import Core
@testable import Session

internal struct IgnoringLearningObserver: LearningObserver {
    func observe(inserted text: String, into focus: FocusSnapshot) {}
}
