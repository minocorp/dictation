import Foundation

extension AccessibilityElement {
    func string(_ attribute: ElementAttribute) -> AccessibilityRead<String> {
        switch read(attribute) {
        case .value(.text(let text)): .value(text)
        case .value(.range), .value(.flag): .unavailable
        case .noValue: .noValue
        case .unavailable: .unavailable
        }
    }

    func range(_ attribute: ElementAttribute) -> AccessibilityRead<NSRange> {
        switch read(attribute) {
        case .value(.range(let range)): .value(range)
        case .value(.text), .value(.flag): .unavailable
        case .noValue: .noValue
        case .unavailable: .unavailable
        }
    }

    func flag(_ attribute: ElementAttribute) -> AccessibilityRead<Bool> {
        switch read(attribute) {
        case .value(.flag(let flag)): .value(flag)
        case .value(.text), .value(.range): .unavailable
        case .noValue: .noValue
        case .unavailable: .unavailable
        }
    }
}
