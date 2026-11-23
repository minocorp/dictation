public import Core
import Foundation

internal enum HUDAnnouncement: Hashable {
    case listening
    case handsFree
    case handsFreeEnding
    case editing
    case processing
    case copied
    case canceled
    case saved
    case noSpeech
    case problem(Problem)

    var text: String {
        switch self {
        case .listening: UIString.string(UIString.hudListening)
        case .handsFree: UIString.string(UIString.a11yHandsFree)
        case .handsFreeEnding: UIString.string(UIString.a11yHandsFreeEnding)
        case .editing: UIString.string(UIString.hudEditing)
        case .processing: UIString.string(UIString.hudProcessing)
        case .copied: UIString.string(UIString.a11yCopied)
        case .canceled: UIString.string(UIString.a11yCanceled)
        case .saved: UIString.string(UIString.a11ySaved)
        case .noSpeech: UIString.string(UIString.hudNoSpeech)
        case .problem(let problem): problemText(problem)
        }
    }

    static func between(_ previous: HUDState, _ current: HUDState) -> HUDAnnouncement? {
        guard previous.kind == current.kind else { return announcement(for: current) }
        if case .handsFree(_, nil) = previous, case .handsFree(_, .some) = current {
            return .handsFreeEnding
        }
        if case .problem(let before) = previous, case .problem(let after) = current,
            before != after
        {
            return .problem(after)
        }
        return nil
    }

    static func announcement(for state: HUDState) -> HUDAnnouncement? {
        switch state {
        case .hidden: nil
        case .listening: .listening
        case .handsFree: .handsFree
        case .editing: .editing
        case .processing: .processing
        case .copied: .copied
        case .canceled: .canceled
        case .saved: .saved
        case .noSpeech: .noSpeech
        case .problem(let problem): .problem(problem)
        }
    }

    private func problemText(_ problem: Problem) -> String {
        let message = UIString.string(problem.message)
        guard problem.fix != nil else { return message }
        return message + ". " + UIString.string(UIString.a11yProblemOpensFix)
    }
}
