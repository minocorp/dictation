public import Core

public struct MicrophoneOption: Hashable, Sendable, Identifiable {
    public let device: InputDevice
    public let name: String

    public var id: InputDevice { device }

    public init(device: InputDevice, name: String) {
        self.device = device
        self.name = name
    }
}
