import AVFoundation
@testable import Recognition
import Testing

internal struct AnalyzerAudioBufferTests {
    @Test
    func sameFormatKeepsTheSamples() throws {
        let format = try #require(
            AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 16_000,
                channels: 1,
                interleaved: false,
            )
        )
        let samples: [Float] = [0, 0.25, -0.5, 1]
        let buffer = try #require(AnalyzerAudioBuffer.make(samples: samples, format: format))
        let channel = try #require(buffer.floatChannelData)[0]
        #expect(
            Array(UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength))) == samples
        )
    }

    @Test
    func integerFormatIsConvertedWithTheSameLength() throws {
        let format = try #require(
            AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: 16_000,
                channels: 1,
                interleaved: false,
            )
        )
        let samples = (0..<1_600).map { Float(0.5 * sin(Double($0) * 0.2)) }
        let buffer = try #require(AnalyzerAudioBuffer.make(samples: samples, format: format))
        #expect(buffer.frameLength == 1_600)
        let channel = try #require(buffer.int16ChannelData)[0]
        #expect(abs(Float(channel[5]) / 32_768 - samples[5]) < 0.001)
    }

    @Test
    func higherRateFormatIsResampled() throws {
        let format = try #require(
            AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 48_000,
                channels: 1,
                interleaved: false,
            )
        )
        let buffer = try #require(
            AnalyzerAudioBuffer.make(
                samples: [Float](repeating: 0.1, count: 1_600),
                format: format,
            )
        )
        #expect(abs(Int(buffer.frameLength) - 4_800) < 200)
    }

    @Test
    func emptyInputGivesNoBuffer() throws {
        let format = try #require(
            AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 16_000,
                channels: 1,
                interleaved: false,
            )
        )
        #expect(AnalyzerAudioBuffer.make(samples: [], format: format) == nil)
    }
}
