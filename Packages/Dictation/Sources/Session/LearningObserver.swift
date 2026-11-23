public import Core

public protocol LearningObserver: Sendable {
    func observe(inserted text: String, into focus: FocusSnapshot)
}
