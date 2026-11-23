@testable import Capture
import Core
import Testing

internal struct InputDeviceSelectionTests {
    static let builtIn = InputDeviceDescription(id: 1, uid: "built-in", isBuiltIn: true)
    static let airPods = InputDeviceDescription(id: 2, uid: "airpods", isBuiltIn: false)
    static let usb = InputDeviceDescription(id: 3, uid: "usb", isBuiltIn: false)

    struct Case: Sendable, CustomTestStringConvertible {
        let name: String
        let request: InputDevice
        let devices: [InputDeviceDescription]
        let defaultInputID: UInt32?
        let expected: InputDeviceDescription?
        let expectedWithFallback: InputDeviceDescription?
        var testDescription: String { name }
    }

    static let cases = [
        Case(
            name: "built-in wins over a Bluetooth default",
            request: .builtIn,
            devices: [airPods, builtIn],
            defaultInputID: 2,
            expected: builtIn,
            expectedWithFallback: builtIn,
        ),
        Case(
            name: "no built-in falls back to the default input",
            request: .builtIn,
            devices: [airPods, usb],
            defaultInputID: 3,
            expected: usb,
            expectedWithFallback: usb,
        ),
        Case(
            name: "no built-in and no default takes the first device",
            request: .builtIn,
            devices: [airPods, usb],
            defaultInputID: nil,
            expected: airPods,
            expectedWithFallback: airPods,
        ),
        Case(
            name: "explicit uid is matched",
            request: .device(uid: "usb"),
            devices: [builtIn, usb],
            defaultInputID: 1,
            expected: usb,
            expectedWithFallback: usb,
        ),
        Case(
            name: "missing explicit device is unavailable but restarts on built-in",
            request: .device(uid: "gone"),
            devices: [builtIn, usb],
            defaultInputID: 3,
            expected: nil,
            expectedWithFallback: builtIn,
        ),
        Case(
            name: "no devices at all",
            request: .builtIn,
            devices: [],
            defaultInputID: nil,
            expected: nil,
            expectedWithFallback: nil,
        ),
    ]

    @Test(arguments: cases)
    func resolvesRequestedDevice(testCase: Case) {
        let strict = InputDeviceSelection.resolve(
            testCase.request,
            among: testCase.devices,
            defaultInputID: testCase.defaultInputID,
        )
        let relaxed = InputDeviceSelection.resolveWithFallback(
            testCase.request,
            among: testCase.devices,
            defaultInputID: testCase.defaultInputID,
        )
        #expect(strict == testCase.expected)
        #expect(relaxed == testCase.expectedWithFallback)
    }
}
