import AVFoundation
public import Core
public import Foundation
import Synchronization

public final class DeviceAudioSource: AudioSource {
    private struct Session {
        let control: CaptureControl
        let url: URL
    }

    public let levels: AsyncStream<Float>

    private let audioDirectory: URL
    private let levelContinuation: AsyncStream<Float>.Continuation
    private let session = Mutex<Session?>(nil)

    public init(audioDirectory: URL) {
        self.audioDirectory = audioDirectory
        let stream = AsyncStream.makeStream(of: Float.self, bufferingPolicy: .bufferingNewest(1))
        levels = stream.stream
        levelContinuation = stream.continuation
    }

    @concurrent
    public func start(
        device: InputDevice,
        id: DictationID,
    ) async throws(CaptureError) -> AudioCapture {
        try checkMicrophoneAccess()
        let url = audioDirectory.appending(path: "\(id.stem).caf")
        let control = CaptureControl()
        let claimed = session.withLock { current in
            guard current?.control.isStopRequested ?? true else { return false }
            current = Session(control: control, url: url)
            return true
        }
        guard claimed else { throw .alreadyRunning }
        let chunks = AsyncStream.makeStream(of: AudioChunk.self)
        let failures = AsyncStream.makeStream(
            of: CaptureError.self,
            bufferingPolicy: .bufferingNewest(1),
        )
        launchDrainThread(
            device: device,
            url: url,
            control: control,
            outputs: CaptureOutputs(chunks: chunks.continuation, failures: failures.continuation),
        )
        await control.waitUntilOpened()
        do {
            try control.openOutcome.get()
        } catch {
            session.withLock { $0 = nil }
            await control.waitUntilFinished()
            try? FileManager.default.removeItem(at: url)
            throw error
        }
        chunks.continuation.onTermination = { _ in control.requestStop() }
        return AudioCapture(chunks: chunks.stream, failures: failures.stream)
    }

    @concurrent
    public func stop() async -> URL? {
        guard let ended = session.withLock({ $0.take() }) else { return nil }
        ended.control.requestStop()
        await ended.control.waitUntilFinished()
        return ended.url
    }

    public func discard(audioAt url: URL) async {
        guard
            url.deletingLastPathComponent().standardizedFileURL
                == audioDirectory
                .standardizedFileURL
        else { return }
        try? FileManager.default.removeItem(at: url)
    }

    private func checkMicrophoneAccess() throws(CaptureError) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .denied, .restricted:
            throw .permissionDenied
        case .authorized, .notDetermined:
            break
        @unknown default:
            break
        }
    }

    private func launchDrainThread(
        device: InputDevice,
        url: URL,
        control: CaptureControl,
        outputs: CaptureOutputs,
    ) {
        let levels = levelContinuation
        let directory = audioDirectory
        let thread = Thread {
            do throws(CaptureError) {
                let writer = try Self.makeWriter(directory: directory, url: url)
                let pipeline = CapturePipeline(writer: writer, outputs: outputs, levels: levels)
                let observer = RouteChangeObserver { control.noteRouteChange() }
                CaptureLoop(
                    request: device,
                    control: control,
                    pipeline: pipeline,
                    observer: observer,
                )
                .run()
            } catch {
                control.reportOpened(.failure(error))
                outputs.chunks.finish()
                outputs.failures.finish()
                control.reportFinished()
            }
        }
        thread.name = "dictation.capture.drain"
        thread.qualityOfService = QualityOfService.userInteractive
        thread.start()
    }

    private static func makeWriter(directory: URL, url: URL) throws(CaptureError) -> CAFWriter {
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
            )
        } catch {
            throw .diskWriteFailed(code: (error as NSError).code)
        }
        return try CAFWriter(url: url)
    }
}
