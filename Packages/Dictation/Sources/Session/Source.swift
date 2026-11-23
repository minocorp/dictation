import Foundation

internal enum Source: Equatable, Sendable {
    case live
    case audio(URL)
    case pasteLast
}
