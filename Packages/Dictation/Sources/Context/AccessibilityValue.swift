import Foundation

internal enum AccessibilityValue: Sendable {
    case text(String)
    case range(NSRange)
    case flag(Bool)
}
