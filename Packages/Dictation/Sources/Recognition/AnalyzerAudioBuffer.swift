import AVFoundation
import Core

internal enum AnalyzerAudioBuffer {
    static func make(samples: [Float], format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard
            !samples.isEmpty,
            let source = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: Double(AudioChunk.sampleRate),
                channels: 1,
                interleaved: false,
            ),
            let input = AVAudioPCMBuffer(
                pcmFormat: source,
                frameCapacity: AVAudioFrameCount(samples.count),
            ),
            let channel = input.floatChannelData?[0]
        else { return nil }
        for (index, sample) in samples.enumerated() {
            channel[index] = sample
        }
        input.frameLength = AVAudioFrameCount(samples.count)
        guard format != source else { return input }
        return converted(input, to: format)
    }

    private static func converted(
        _ input: AVAudioPCMBuffer,
        to format: AVAudioFormat,
    ) -> AVAudioPCMBuffer? {
        guard let converter = AVAudioConverter(from: input.format, to: format) else { return nil }
        let ratio = format.sampleRate / input.format.sampleRate
        let capacity = AVAudioFrameCount(Double(input.frameLength) * ratio) + 1_024
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else {
            return nil
        }
        var isInputPending = true
        var failure: NSError?
        let status = converter.convert(to: output, error: &failure) { _, inputStatus in
            guard isInputPending else {
                inputStatus.pointee = .endOfStream
                return nil
            }
            isInputPending = false
            inputStatus.pointee = .haveData
            return input
        }
        guard failure == nil, status != .error else { return nil }
        return output
    }
}
