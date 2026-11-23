public enum GuardFailure: Hashable, Sendable {
    case emptyOutput
    case inventedNumber
    case missingNumber
    case missingTechnicalToken
    case lengthRatio
    case editDistance
    case scriptChanged
    case replyPattern
    case structureLeak
    case droppedLeadIn
    case novelWords
    case novelSyllables
    case unspokenMeridiem
    case exampleLeak
}
