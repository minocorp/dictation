import AVFoundation

internal actor MicrophoneLevelProbe {
    private static let floorDecibels: Float = -60
    private static let bufferSize: AVAudioFrameCount = 1_024
    private static let idleWait = Duration.seconds(3_600)

    private let engine = AVAudioEngine()

    nonisolated static func levels() -> AsyncStream<Float> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let probe = MicrophoneLevelProbe()
            let task = Task {
                await probe.run(into: continuation)
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func run(into continuation: AsyncStream<Float>.Continuation) async {
        guard !Task.isCancelled, start(into: continuation) else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: Self.idleWait)
        }
        stop()
    }

    private func start(into continuation: AsyncStream<Float>.Continuation) -> Bool {
        let input = engine.inputNode
        input.installTap(onBus: 0, bufferSize: Self.bufferSize, format: nil) { buffer, _ in
            continuation.yield(Self.normalizedLevel(of: buffer))
        }
        do {
            try engine.start()
            return true
        } catch {
            AppLog.failure("microphone probe", error)
            input.removeTap(onBus: 0)
            continuation.finish()
            return false
        }
    }

    private func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
    }

    private nonisolated static func normalizedLevel(of buffer: AVAudioPCMBuffer) -> Float {
        guard let samples = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return 0 }
        let count = Int(buffer.frameLength)
        var sum: Float = 0
        for index in 0..<count {
            sum += samples[index] * samples[index]
        }
        let decibels = 10 * log10(max(sum / Float(count), .leastNormalMagnitude))
        return min(max((decibels - floorDecibels) / -floorDecibels, 0), 1)
    }
}
