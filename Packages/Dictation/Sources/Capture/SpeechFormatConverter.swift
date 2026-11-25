import AVFoundation
import Core
import Foundation
import os

internal final class SpeechFormatConverter {
    private static let mixedChannelCount = 2
    private static let tailPadding = 64
    private static let logger = Logger(dictationCategory: "Capture")

    private let channelCount: Int
    private let sourceRate: Double
    private let resampler: AVAudioConverter?
    private let sourceFormat: AVAudioFormat?

    init?(sourceRate: Double, channelCount: Int) {
        guard sourceRate > 0, channelCount > 0 else { return nil }
        self.sourceRate = sourceRate
        self.channelCount = channelCount
        if sourceRate == Double(AudioChunk.sampleRate) {
            resampler = nil
            sourceFormat = nil
            return
        }
        guard
            let source = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: sourceRate,
                channels: 1,
                interleaved: false,
            ),
            let target = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: Double(AudioChunk.sampleRate),
                channels: 1,
                interleaved: false,
            ),
            let converter = AVAudioConverter(from: source, to: target)
        else { return nil }
        converter.primeMethod = .none
        converter.sampleRateConverterQuality = AVAudioQuality.max.rawValue
        resampler = converter
        sourceFormat = source
    }

    func convert(interleaved samples: UnsafeBufferPointer<Float>) -> [Float] {
        resample(mixToMono(samples), isEnd: false)
    }

    func flush() -> [Float] {
        resample([], isEnd: true)
    }

    private func mixToMono(_ samples: UnsafeBufferPointer<Float>) -> [Float] {
        let frames = samples.count / channelCount
        let mixed = min(channelCount, Self.mixedChannelCount)
        return (0..<frames)
            .map { frame in
                var sum: Float = 0
                for channel in 0..<mixed {
                    sum += samples[frame * channelCount + channel]
                }
                return sum / Float(mixed)
            }
    }

    private func resample(_ mono: [Float], isEnd: Bool) -> [Float] {
        guard let resampler, let sourceFormat else { return mono }
        let ratio = Double(AudioChunk.sampleRate) / sourceRate
        let capacity =
            AVAudioFrameCount(Double(mono.count) * ratio) + AVAudioFrameCount(Self.tailPadding)
        guard
            let input = AVAudioPCMBuffer(
                pcmFormat: sourceFormat,
                frameCapacity: AVAudioFrameCount(max(mono.count, 1)),
            ),
            let output = AVAudioPCMBuffer(
                pcmFormat: resampler.outputFormat,
                frameCapacity: capacity,
            ),
            let channel = input.floatChannelData?[0]
        else { return [] }
        for (index, sample) in mono.enumerated() {
            channel[index] = sample
        }
        input.frameLength = AVAudioFrameCount(mono.count)
        return run(resampler, input: input, output: output, isEnd: isEnd)
    }

    private func run(
        _ converter: AVAudioConverter,
        input: AVAudioPCMBuffer,
        output: AVAudioPCMBuffer,
        isEnd: Bool,
    ) -> [Float] {
        var isInputPending = input.frameLength > 0
        var failure: NSError?
        converter.convert(to: output, error: &failure) { _, status in
            guard isInputPending else {
                status.pointee = isEnd ? .endOfStream : .noDataNow
                return nil
            }
            isInputPending = false
            status.pointee = .haveData
            return input
        }
        if let failure {
            Self.logger.error("resample failed code=\(failure.code, privacy: .public)")
            return []
        }
        guard let data = output.floatChannelData?[0] else { return [] }
        return Array(UnsafeBufferPointer(start: data, count: Int(output.frameLength)))
    }
}
