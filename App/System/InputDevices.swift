import AVFoundation
import Core
import UI

internal enum InputDevices {
    static func options() -> [MicrophoneOption] {
        let discovered = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified,
        )
        let devices = discovered.devices.map {
            MicrophoneOption(device: .device(uid: $0.uniqueID), name: $0.localizedName)
        }
        let builtIn = MicrophoneOption(device: .builtIn, name: builtInName())
        return [builtIn] + devices
    }

    static func isDefaultInputBluetooth() -> Bool {
        guard let device = AVCaptureDevice.default(for: .audio) else { return false }
        let bluetooth = [kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE]
        return bluetooth.contains(UInt32(bitPattern: device.transportType))
    }

    private static func builtInName() -> String {
        let builtIn =
            AVCaptureDevice.DiscoverySession(
                deviceTypes: [.microphone],
                mediaType: .audio,
                position: .unspecified,
            )
            .devices
            .first { $0.transportType == Int32(bitPattern: kAudioDeviceTransportTypeBuiltIn) }
        return builtIn?.localizedName ?? "Built-in"
    }
}
