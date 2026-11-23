internal import AVFoundation
internal import Core

internal enum AudioDecoder {
    static func samples(from file: URL) throws(EvalError) -> [Float] {
        do {
            let source = try AVAudioFile(forReading: file)
            let input = try buffer(of: source)
            return try resampled(input, name: file.lastPathComponent)
        } catch let error as EvalError {
            throw error
        } catch {
            throw .audio("\(file.lastPathComponent): \(error.localizedDescription)")
        }
    }

    private static func buffer(of file: AVAudioFile) throws -> AVAudioPCMBuffer {
        guard
            let input = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat,
                frameCapacity: AVAudioFrameCount(file.length),
            )
        else { throw EvalError.audio("cannot allocate input buffer") }
        try file.read(into: input)
        return input
    }

    private static func resampled(_ input: AVAudioPCMBuffer, name: String) throws -> [Float] {
        guard
            let target = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: Double(AudioChunk.sampleRate),
                channels: 1,
                interleaved: false,
            ),
            let converter = AVAudioConverter(from: input.format, to: target)
        else { throw EvalError.audio("cannot convert \(name)") }
        let ratio = target.sampleRate / input.format.sampleRate
        let capacity = AVAudioFrameCount(Double(input.frameLength) * ratio) + 1024
        guard let output = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: capacity) else {
            throw EvalError.audio("cannot allocate output for \(name)")
        }
        var supplied = false
        var failure: NSError?
        converter.convert(to: output, error: &failure) { _, status in
            if supplied {
                status.pointee = .endOfStream
                return nil
            }
            supplied = true
            status.pointee = .haveData
            return input
        }
        if let failure { throw EvalError.audio(failure.localizedDescription) }
        guard let channel = output.floatChannelData?[0] else {
            throw EvalError.audio("no samples in \(name)")
        }
        return Array(UnsafeBufferPointer(start: channel, count: Int(output.frameLength)))
    }
}
