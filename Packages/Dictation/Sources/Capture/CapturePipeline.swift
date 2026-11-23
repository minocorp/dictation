import Core
import Foundation
import os

internal final class CapturePipeline {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "",
        category: "Capture",
    )

    private let writer: CAFWriter
    private let outputs: CaptureOutputs
    private let levels: AsyncStream<Float>.Continuation
    private var converter: SpeechFormatConverter?
    private var scratch: [Float] = []
    private var emittedSamples = 0
    private var hasReportedWriteFailure = false

    init(
        writer: CAFWriter,
        outputs: CaptureOutputs,
        levels: AsyncStream<Float>.Continuation,
    ) {
        self.writer = writer
        self.outputs = outputs
        self.levels = levels
    }

    func attach(sampleRate: Double, channelCount: Int) -> Bool {
        converter = SpeechFormatConverter(sourceRate: sampleRate, channelCount: channelCount)
        return converter != nil
    }

    func drain(_ ring: SPSCRingBuffer, channelCount: Int) {
        guard let converter else { return }
        let frames = ring.availableToRead / channelCount
        guard frames > 0 else { return }
        if scratch.count < frames * channelCount {
            scratch = [Float](repeating: 0, count: frames * channelCount)
        }
        let read = scratch.withUnsafeMutableBufferPointer {
            ring.read(into: UnsafeMutableBufferPointer(rebasing: $0[0..<frames * channelCount]))
        }
        let converted = scratch.withUnsafeBufferPointer {
            converter.convert(interleaved: UnsafeBufferPointer(rebasing: $0[0..<read]))
        }
        emit(converted)
    }

    func detach(_ ring: SPSCRingBuffer, channelCount: Int) {
        drain(ring, channelCount: channelCount)
        if let converter { emit(converter.flush()) }
        converter = nil
    }

    func finish() {
        do {
            try writer.finish()
        } catch {
            report(error)
        }
        outputs.chunks.finish()
        outputs.failures.finish()
    }

    func report(_ error: CaptureError) {
        Self.logger.error("capture failed code=\(error.diagnosticCode, privacy: .public)")
        outputs.failures.yield(error)
    }

    private func emit(_ samples: [Float]) {
        guard !samples.isEmpty else { return }
        do {
            try writer.append(samples)
        } catch {
            reportWriteFailureOnce(error)
        }
        outputs.chunks.yield(AudioChunk(samples: samples, startSample: emittedSamples))
        emittedSamples += samples.count
        levels.yield(AudioLevel.normalized(samples))
    }

    private func reportWriteFailureOnce(_ error: CaptureError) {
        guard !hasReportedWriteFailure else { return }
        hasReportedWriteFailure = true
        report(error)
    }
}
