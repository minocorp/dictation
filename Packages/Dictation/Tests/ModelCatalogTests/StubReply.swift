import Foundation

internal enum StubReply: Sendable {
    case body(Data)
    case stalled(Data, deliveredBytes: Int)
    case failure(URLError)
    case status(Int)
}
