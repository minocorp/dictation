import AppKit
import Carbon
package import Foundation

package struct UCKeyLayout: KeyTranslating {
    private static let bufferLength = 4

    private let layoutData: Data
    private let keyboardType: UInt32

    package init(layoutData: Data) {
        self.layoutData = layoutData
        keyboardType = CGEventSource(stateID: .hidSystemState)?.keyboardType ?? 0
    }

    package func characters(forKeyCode keyCode: UInt16, commandHeld: Bool) -> String {
        layoutData.withUnsafeBytes { bytes in
            guard let base = bytes.baseAddress else { return "" }
            let layout = base.assumingMemoryBound(to: UCKeyboardLayout.self)
            var deadKeyState: UInt32 = 0
            var length = 0
            var buffer = [UniChar](repeating: 0, count: Self.bufferLength)
            let status = UCKeyTranslate(
                layout,
                keyCode,
                UInt16(kUCKeyActionDown),
                commandHeld ? UInt32(cmdKey >> 8) : 0,
                keyboardType,
                OptionBits(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                Self.bufferLength,
                &length,
                &buffer,
            )
            guard status == noErr else { return "" }
            return String(utf16CodeUnits: buffer, count: length)
        }
    }
}
