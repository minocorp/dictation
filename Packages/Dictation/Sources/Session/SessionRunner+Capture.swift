import Core
import Foundation

extension SessionRunner {
    func startCapture(_ id: DictationID, device: InputDevice) {
        let audio = inputs.audio
        spawnSerial(.audio) { [weak self] in
            TimingLog.mark("capture-open", for: id)
            let started = await Result.awaiting { () async throws(CaptureError) -> AudioCapture in
                try await audio.start(device: device, id: id)
            }
            switch started {
            case .success(let capture): self?.captureStarted(capture, id: id)
            case .failure(let error): self?.send(.result(id, .failed(.capture(error))))
            }
        }
    }

    func stopCapture(_ id: DictationID) {
        let audio = inputs.audio
        spawnSerial(.audio) { [weak self] in
            guard let self, liveCapture == id else { return }
            liveCapture = nil
            TimingLog.keyUp(id)
            let url = await audio.stop()
            TimingLog.mark("capture-closed", for: id)
            send(.input(id, .finished(audioURL: url)))
        }
    }

    func discardCapture(_ id: DictationID) {
        let audio = inputs.audio
        spawnSerial(.audio) { [weak self] in
            guard let self, liveCapture == id else { return }
            liveCapture = nil
            guard let url = await audio.stop() else { return }
            await audio.discard(audioAt: url)
        }
    }

    func discardAudio(_ url: URL) {
        let audio = inputs.audio
        spawnSerial(.audio) {
            await audio.discard(audioAt: url)
        }
    }

    func readAudio(_ id: DictationID, url: URL) {
        do throws(SpeechError) {
            read(id, segments: try inputs.files.segments(of: url, id: id))
        } catch {
            send(.result(id, .failed(.speech(error))))
        }
    }

    func readFocus(_ id: DictationID) {
        let reader = outputs.focus
        spawn(id) { [weak self] in
            let snapshot = await reader.snapshot()
            self?.send(.input(id, .focus(snapshot)))
        }
    }

    func readSelection(_ id: DictationID) {
        let reader = outputs.focus
        spawn(id) { [weak self] in
            let selection = await reader.selection(
                maxCharacters: SessionTiming.selectionCharacterLimit
            )
            self?.send(.input(id, .selection(selection)))
        }
    }

    private func captureStarted(_ capture: AudioCapture, id: DictationID) {
        TimingLog.mark("capture-started", for: id)
        liveCapture = id
        preheatEngines(for: id)
        read(id, segments: inputs.voice.segments(of: capture.chunks, id: id))
        watchFailures(of: capture, id: id)
        send(.input(id, .started))
    }

    private func watchFailures(of capture: AudioCapture, id: DictationID) {
        let failures = capture.failures
        spawn(id) { [weak self] in
            for await error in failures {
                self?.send(.result(id, .failed(.capture(error))))
            }
        }
    }

    private func read(_ id: DictationID, segments: AsyncStream<Segment>) {
        captures[id] = Task { [weak self] in
            for await segment in segments {
                TimingLog.mark(
                    "segment-emitted",
                    "index=\(segment.index) final=\(segment.isFinal) samples=\(segment.audio.count)",
                    for: id,
                )
                self?.send(.input(id, .segment(segment)))
            }
            self?.captures[id] = nil
            TimingLog.mark("segments-ended", for: id)
            self?.send(.input(id, .segmentsEnded))
        }
    }
}
