import Core
import Foundation

internal final class CaptureLoop {
    private static let pollInterval: TimeInterval = 0.01
    private static let routeSettleInterval: TimeInterval = 0.15

    private struct ActiveInput {
        let hal: HALInput
        let device: InputDeviceDescription
    }

    private let request: InputDevice
    private let control: CaptureControl
    private let pipeline: CapturePipeline
    private let observer: RouteChangeObserver
    private var active: ActiveInput?

    init(
        request: InputDevice,
        control: CaptureControl,
        pipeline: CapturePipeline,
        observer: RouteChangeObserver,
    ) {
        self.request = request
        self.control = control
        self.pipeline = pipeline
        self.observer = observer
    }

    func run() {
        do {
            active = try openInput(strict: true)
            control.reportOpened(.success(()))
        } catch {
            control.reportOpened(.failure(error))
            shutDown()
            return
        }
        while !control.isStopRequested {
            if control.consumeRouteChange() { followRouteChange() }
            if let active {
                pipeline.drain(active.hal.ring, channelCount: active.hal.channelCount)
            }
            Thread.sleep(forTimeInterval: Self.pollInterval)
        }
        shutDown()
    }

    private func openInput(strict: Bool) throws(CaptureError) -> ActiveInput? {
        let devices = AudioDeviceDirectory.inputDevices()
        guard !devices.isEmpty else {
            if strict { throw .noInputDevice }
            return nil
        }
        let defaultID = AudioDeviceDirectory.defaultInputID()
        let chosen =
            strict
            ? InputDeviceSelection.resolve(request, among: devices, defaultInputID: defaultID)
            : InputDeviceSelection.resolveWithFallback(
                request,
                among: devices,
                defaultInputID: defaultID,
            )
        guard let chosen else {
            if strict { throw .deviceUnavailable }
            return nil
        }
        let hal = try HALInput.open(deviceID: chosen.id)
        guard pipeline.attach(sampleRate: hal.sampleRate, channelCount: hal.channelCount) else {
            hal.stop()
            throw .deviceUnavailable
        }
        observer.watch(device: chosen.id)
        return ActiveInput(hal: hal, device: chosen)
    }

    private func followRouteChange() {
        Thread.sleep(forTimeInterval: Self.routeSettleInterval)
        _ = control.consumeRouteChange()
        guard needsReopen() else { return }
        closeInput()
        do {
            active = try openInput(strict: false)
        } catch {
            pipeline.report(error)
            return
        }
        if active == nil { pipeline.report(.noInputDevice) }
    }

    private func needsReopen() -> Bool {
        guard let active else { return true }
        let devices = AudioDeviceDirectory.inputDevices()
        let best = InputDeviceSelection.resolveWithFallback(
            request,
            among: devices,
            defaultInputID: AudioDeviceDirectory.defaultInputID(),
        )
        let rate = AudioDeviceDirectory.nominalSampleRate(of: active.device.id)
        return best != active.device || rate != active.hal.sampleRate
    }

    private func closeInput() {
        guard let active else { return }
        active.hal.stop()
        pipeline.detach(active.hal.ring, channelCount: active.hal.channelCount)
        observer.watch(device: nil)
        self.active = nil
    }

    private func shutDown() {
        closeInput()
        observer.stop()
        pipeline.finish()
        control.reportFinished()
    }
}
