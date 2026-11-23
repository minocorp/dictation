import ApplicationServices
import Core

internal enum ModifierKey: UInt16 {
    case rightCommand = 54
    case leftCommand = 55
    case leftShift = 56
    case leftOption = 58
    case leftControl = 59
    case rightShift = 60
    case rightOption = 61
    case rightControl = 62
    case function = 63

    var modifier: KeyModifiers {
        switch self {
        case .rightCommand, .leftCommand: .command
        case .leftShift, .rightShift: .shift
        case .leftOption, .rightOption: .option
        case .leftControl, .rightControl: .control
        case .function: .function
        }
    }

    var pressedFlag: CGEventFlags {
        switch self {
        case .rightCommand: CGEventFlags(rawValue: 0x10)
        case .leftCommand: CGEventFlags(rawValue: 0x08)
        case .leftShift: CGEventFlags(rawValue: 0x02)
        case .rightShift: CGEventFlags(rawValue: 0x04)
        case .leftOption: CGEventFlags(rawValue: 0x20)
        case .rightOption: CGEventFlags(rawValue: 0x40)
        case .leftControl: CGEventFlags(rawValue: 0x01)
        case .rightControl: CGEventFlags(rawValue: 0x2000)
        case .function: .maskSecondaryFn
        }
    }
}
