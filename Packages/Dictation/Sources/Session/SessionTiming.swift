import Core

internal enum SessionTiming {
    static let processingDelay = Duration.milliseconds(250)
    static let handsFreeSecond = Duration.seconds(1)
    static let countdownWindow = Duration.seconds(10)
    static let copiedDisplay = Duration.seconds(3)
    static let canceledDisplay = Duration.seconds(5)
    static let savedDisplay = Duration.seconds(2)
    static let noSpeechDisplay = Duration.milliseconds(1_500)
    static let problemDisplay = Duration.seconds(8)
    static let selectionCharacterLimit = 4_000
    static let contextCharacterLimit = 200

    static func expiry(of hud: HUDState) -> Duration? {
        switch hud {
        case .hidden, .listening, .handsFree, .editing, .processing: nil
        case .copied: copiedDisplay
        case .canceled: canceledDisplay
        case .saved: savedDisplay
        case .noSpeech: noSpeechDisplay
        case .problem: problemDisplay
        }
    }
}
