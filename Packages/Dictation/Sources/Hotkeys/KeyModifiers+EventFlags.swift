import ApplicationServices
import Core

extension KeyModifiers {
    init(flags: CGEventFlags, includesFunction: Bool = true) {
        var modifiers = KeyModifiers()
        if flags.contains(.maskShift) { modifiers.insert(.shift) }
        if flags.contains(.maskControl) { modifiers.insert(.control) }
        if flags.contains(.maskAlternate) { modifiers.insert(.option) }
        if flags.contains(.maskCommand) { modifiers.insert(.command) }
        if includesFunction, flags.contains(.maskSecondaryFn) { modifiers.insert(.function) }
        self = modifiers
    }
}
