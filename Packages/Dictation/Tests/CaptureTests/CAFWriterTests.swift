import AVFoundation
@testable import Capture
import Core
import Foundation
import Testing

internal struct CAFWriterTests {
    @Test
    func finishedFileRecoversEverySample() throws {
        let scratch = try ScratchDirectory()
        let url = scratch.file("a.caf")
        let samples = Tone.mono(frequency: 440, rate: 16_000, seconds: 0.5)
        let writer = try CAFWriter(url: url)
        try writer.append(Array(samples.prefix(3_000)))
        try writer.append(Array(samples.dropFirst(3_000)))
        try writer.finish()
        #expect(try CAFRecovery.samples(at: url) == samples)
    }

    @Test
    func finishedFileIsReadableByAudioFile() throws {
        let scratch = try ScratchDirectory()
        let url = scratch.file("a.caf")
        let samples = Tone.mono(frequency: 300, rate: 16_000, seconds: 0.25)
        let writer = try CAFWriter(url: url)
        try writer.append(samples)
        try writer.finish()
        let file = try AVAudioFile(forReading: url)
        #expect(file.processingFormat.sampleRate == 16_000)
        #expect(file.processingFormat.channelCount == 1)
        #expect(file.length == AVAudioFramePosition(samples.count))
        let buffer = try #require(
            AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: 8_000)
        )
        try file.read(into: buffer)
        let read = Array(
            UnsafeBufferPointer(
                start: try #require(buffer.floatChannelData)[0],
                count: Int(buffer.frameLength),
            )
        )
        #expect(read == samples)
    }

    @Test
    func unfinishedFileRecoversWhatWasAppended() throws {
        let scratch = try ScratchDirectory()
        let url = scratch.file("crash.caf")
        let samples = Tone.mono(frequency: 440, rate: 16_000, seconds: 0.25)
        let writer = try CAFWriter(url: url)
        try writer.append(samples)
        #expect(try CAFRecovery.samples(at: url) == samples)
    }

    @Test
    func unfinishedFileIsReadableByAudioFile() throws {
        let scratch = try ScratchDirectory()
        let url = scratch.file("crash.caf")
        let samples = Tone.mono(frequency: 440, rate: 16_000, seconds: 0.25)
        let writer = try CAFWriter(url: url)
        try writer.append(samples)
        let file = try AVAudioFile(forReading: url)
        #expect(file.length == AVAudioFramePosition(samples.count))
    }

    @Test(arguments: [0, 1, 2, 3])
    func fileTruncatedMidSampleDropsOnlyThePartialSample(extraBytes: Int) throws {
        let scratch = try ScratchDirectory()
        let url = scratch.file("cut.caf")
        let samples = Tone.mono(frequency: 440, rate: 16_000, seconds: 0.25)
        let writer = try CAFWriter(url: url)
        try writer.append(samples)
        try writer.finish()
        let keptSamples = 2_000
        let handle = try FileHandle(forUpdating: url)
        try handle.truncate(
            atOffset: UInt64(CAFFormat.samplesOffset + keptSamples * 4 + extraBytes)
        )
        try handle.close()
        #expect(try CAFRecovery.samples(at: url) == Array(samples.prefix(keptSamples)))
    }

    @Test
    func headerOnlyFileRecoversNothing() throws {
        let scratch = try ScratchDirectory()
        let url = scratch.file("empty.caf")
        let writer = try CAFWriter(url: url)
        try writer.finish()
        #expect(try CAFRecovery.samples(at: url).isEmpty)
    }

    @Test(arguments: [0, 7, 30, 60])
    func truncatedHeaderIsRejected(length: Int) throws {
        let scratch = try ScratchDirectory()
        let url = scratch.file("short.caf")
        try CAFFormat.header().prefix(length).write(to: url)
        #expect(throws: CaptureError.diskWriteFailed(code: CAFRecovery.malformedFileCode)) {
            try CAFRecovery.samples(at: url)
        }
    }

    @Test
    func otherFileTypesAreRejected() throws {
        let scratch = try ScratchDirectory()
        let url = scratch.file("other.caf")
        try Data("RIFF....WAVEfmt ".utf8).write(to: url)
        #expect(throws: CaptureError.diskWriteFailed(code: CAFRecovery.malformedFileCode)) {
            try CAFRecovery.samples(at: url)
        }
    }

    @Test
    func missingFileReportsDiskError() throws {
        let scratch = try ScratchDirectory()
        #expect(throws: CaptureError.self) {
            try CAFRecovery.samples(at: scratch.file("none.caf"))
        }
    }
}
