import CoreAudio
import Foundation

internal final class RouteChangeObserver {
    private static let systemSelectors = [
        kAudioHardwarePropertyDevices,
        kAudioHardwarePropertyDefaultInputDevice,
    ]
    private static let deviceSelectors = [
        kAudioDevicePropertyDeviceIsAlive,
        kAudioDevicePropertyNominalSampleRate,
    ]

    private let queue = DispatchQueue(label: "dictation.capture.route-changes")
    private let listener: AudioObjectPropertyListenerBlock
    private var watchedDevice: AudioObjectID?

    init(onChange: @escaping @Sendable () -> Void) {
        listener = { _, _ in onChange() }
        for selector in Self.systemSelectors {
            register(AudioObjectID(kAudioObjectSystemObject), selector)
        }
    }

    func watch(device: AudioObjectID?) {
        guard device != watchedDevice else { return }
        if let watchedDevice {
            for selector in Self.deviceSelectors { unregister(watchedDevice, selector) }
        }
        watchedDevice = device
        if let device {
            for selector in Self.deviceSelectors { register(device, selector) }
        }
    }

    func stop() {
        watch(device: nil)
        for selector in Self.systemSelectors {
            unregister(AudioObjectID(kAudioObjectSystemObject), selector)
        }
    }

    private func register(_ object: AudioObjectID, _ selector: AudioObjectPropertySelector) {
        var address = Self.address(selector)
        AudioObjectAddPropertyListenerBlock(object, &address, queue, listener)
    }

    private func unregister(_ object: AudioObjectID, _ selector: AudioObjectPropertySelector) {
        var address = Self.address(selector)
        AudioObjectRemovePropertyListenerBlock(object, &address, queue, listener)
    }

    private static func address(
        _ selector: AudioObjectPropertySelector
    ) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain,
        )
    }
}
