import AppKit
import Core

internal struct SystemModifierState: ModifierState {
    private static let functionKeyCode: CGKeyCode = 63

    func heldModifiers() -> KeyModifiers {
        let flags = CGEventSource.flagsState(.hidSystemState)
        var held: KeyModifiers = []
        if flags.contains(.maskShift) { held.insert(.shift) }
        if flags.contains(.maskControl) { held.insert(.control) }
        if flags.contains(.maskAlternate) { held.insert(.option) }
        if flags.contains(.maskCommand) { held.insert(.command) }
        if CGEventSource.keyState(.hidSystemState, key: Self.functionKeyCode) {
            held.insert(.function)
        }
        return held
    }
}
