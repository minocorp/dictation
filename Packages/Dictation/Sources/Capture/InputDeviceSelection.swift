import Core

internal enum InputDeviceSelection {
    static func resolve(
        _ request: InputDevice,
        among devices: [InputDeviceDescription],
        defaultInputID: UInt32?,
    ) -> InputDeviceDescription? {
        switch request {
        case .builtIn:
            devices.first(where: \.isBuiltIn)
                ?? devices.first { $0.id == defaultInputID }
                ?? devices.first
        case .device(let uid):
            devices.first { $0.uid == uid }
        }
    }

    static func resolveWithFallback(
        _ request: InputDevice,
        among devices: [InputDeviceDescription],
        defaultInputID: UInt32?,
    ) -> InputDeviceDescription? {
        resolve(request, among: devices, defaultInputID: defaultInputID)
            ?? resolve(.builtIn, among: devices, defaultInputID: defaultInputID)
    }
}
