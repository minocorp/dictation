internal enum AccessibilityRead<Value: Sendable>: Sendable {
    case value(Value)
    case noValue
    case unavailable

    var value: Value? {
        switch self {
        case .value(let value): value
        case .noValue, .unavailable: nil
        }
    }
}
