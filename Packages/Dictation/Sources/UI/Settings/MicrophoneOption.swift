public import Core

public struct MicrophoneOption: Hashable, Sendable, Identifiable {
    public static let builtIn = MicrophoneOption(device: .builtIn, deviceName: nil)

    public let device: InputDevice
    let deviceName: String?

    public var id: InputDevice { device }

    public init(uid: String, name: String) {
        self.init(device: .device(uid: uid), deviceName: name)
    }

    private init(device: InputDevice, deviceName: String?) {
        self.device = device
        self.deviceName = deviceName
    }
}
