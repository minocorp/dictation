public import Foundation

public protocol AudioSource: Sendable {
    var levels: AsyncStream<Float> { get }

    func start(device: InputDevice, id: DictationID) async throws(CaptureError) -> AudioCapture
    func stop() async -> URL?
    func discard(audioAt url: URL) async
}
