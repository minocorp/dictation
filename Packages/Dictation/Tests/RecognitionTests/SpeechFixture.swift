import AVFoundation
import Foundation

internal enum SpeechFixture {
    static let sayPath = "/usr/bin/say"

    static var isSayAvailable: Bool {
        FileManager.default.isExecutableFile(atPath: sayPath)
    }

    static func spoken(_ text: String, voice: String? = nil) throws -> [Float] {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).caf")
        defer { try? FileManager.default.removeItem(at: url) }
        let process = Process()
        process.executableURL = URL(filePath: sayPath)
        var arguments = ["-o", url.path(percentEncoded: false), "--data-format=LEF32@16000"]
        if let voice { arguments += ["-v", voice] }
        process.arguments = arguments + [text]
        try process.run()
        process.waitUntilExit()
        let file = try AVAudioFile(forReading: url)
        guard
            let buffer = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat,
                frameCapacity: AVAudioFrameCount(file.length),
            )
        else { return [] }
        try file.read(into: buffer)
        guard let channel = buffer.floatChannelData?[0] else { return [] }
        return Array(UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength)))
    }

    static func silence(seconds: Double) -> [Float] {
        [Float](repeating: 0, count: Int(seconds * 16_000))
    }
}
