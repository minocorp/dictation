import AVFoundation
import Core
import UI

internal enum InputDevices {
    private static let builtInTransport = Int32(bitPattern: kAudioDeviceTransportTypeBuiltIn)

    static func options() -> [MicrophoneOption] {
        let discovered = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified,
        )
        let devices = discovered.devices
            .filter { $0.transportType != builtInTransport }
            .map { MicrophoneOption(uid: $0.uniqueID, name: $0.localizedName) }
        return [.builtIn] + devices
    }

    static func isDefaultInputBluetooth() -> Bool {
        guard let device = AVCaptureDevice.default(for: .audio) else { return false }
        let bluetooth = [kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE]
        return bluetooth.contains(UInt32(bitPattern: device.transportType))
    }
}
