@testable import Capture
import Core
import Foundation
import Testing

internal struct SpeechFormatConverterTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let rate: Double
        let channels: Int
        var testDescription: String { "\(Int(rate)) Hz, \(channels) ch" }
    }

    static let cases = [
        Case(rate: 48_000, channels: 1),
        Case(rate: 48_000, channels: 2),
        Case(rate: 44_100, channels: 1),
        Case(rate: 24_000, channels: 2),
        Case(rate: 16_000, channels: 1),
        Case(rate: 8_000, channels: 1),
    ]

    @Test(arguments: cases)
    func toneKeepsFrequencyAndDuration(testCase: Case) throws {
        let converter = try #require(
            SpeechFormatConverter(sourceRate: testCase.rate, channelCount: testCase.channels)
        )
        let input = Tone.interleaved(
            frequency: 440,
            rate: testCase.rate,
            channels: testCase.channels,
            seconds: 1,
        )
        let output = converted(input, with: converter, blockFrames: 480 * testCase.channels)
        #expect(abs(output.count - AudioChunk.sampleRate) < 400)
        let body = Array(output.dropFirst(800).dropLast(800))
        let target = Tone.power(of: body, at: 440, rate: 16_000)
        let neighbour = Tone.power(of: body, at: 1_500, rate: 16_000)
        #expect(target > 0.2)
        #expect(neighbour < target / 50)
    }

    @Test
    func blockSizeDoesNotChangeTheOutput() throws {
        let input = Tone.interleaved(frequency: 300, rate: 48_000, channels: 1, seconds: 0.5)
        let whole = try #require(SpeechFormatConverter(sourceRate: 48_000, channelCount: 1))
        let split = try #require(SpeechFormatConverter(sourceRate: 48_000, channelCount: 1))
        let one = converted(input, with: whole, blockFrames: input.count)
        let many = converted(input, with: split, blockFrames: 333)
        #expect(abs(one.count - many.count) <= 2)
        let compared = min(one.count, many.count) - 64
        let drift = zip(one.prefix(compared), many.prefix(compared)).map { abs($0 - $1) }.max()
        #expect((drift ?? 1) < 0.05)
    }

    @Test
    func channelsBeyondTheFirstTwoAreIgnored() throws {
        let converter = try #require(SpeechFormatConverter(sourceRate: 16_000, channelCount: 4))
        let input: [Float] = [1, 0, 9, 9, 0, 1, 9, 9]
        let output = input.withUnsafeBufferPointer { converter.convert(interleaved: $0) }
        #expect(output == [0.5, 0.5])
    }

    @Test
    func sixteenKilohertzMonoPassesThrough() throws {
        let converter = try #require(SpeechFormatConverter(sourceRate: 16_000, channelCount: 1))
        let input: [Float] = [0.1, -0.2, 0.3]
        let output = input.withUnsafeBufferPointer { converter.convert(interleaved: $0) }
        #expect(output == input)
        #expect(converter.flush().isEmpty)
    }

    @Test
    func invalidFormatIsRejected() {
        #expect(SpeechFormatConverter(sourceRate: 0, channelCount: 1) == nil)
        #expect(SpeechFormatConverter(sourceRate: 48_000, channelCount: 0) == nil)
    }

    private func converted(
        _ input: [Float],
        with converter: SpeechFormatConverter,
        blockFrames: Int,
    ) -> [Float] {
        var output: [Float] = []
        for start in stride(from: 0, to: input.count, by: blockFrames) {
            let block = Array(input[start..<min(start + blockFrames, input.count)])
            output += block.withUnsafeBufferPointer { converter.convert(interleaved: $0) }
        }
        return output + converter.flush()
    }
}
