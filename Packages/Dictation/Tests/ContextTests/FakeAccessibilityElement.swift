@testable import Context
import Foundation

internal struct FakeAccessibilityElement: AccessibilityElement {
    var identity = 7
    var attributes: [ElementAttribute: AccessibilityRead<AccessibilityValue>] = [:]
    var fullText: String?
    var supportsRangeQuery = true

    func read(_ attribute: ElementAttribute) -> AccessibilityRead<AccessibilityValue> {
        attributes[attribute] ?? .noValue
    }

    func text(in range: NSRange) -> AccessibilityRead<String> {
        guard supportsRangeQuery, let fullText else { return .noValue }
        let units = Array(fullText.utf16)
        let slice = units[range.location..<range.location + range.length]
        return .value(String(decoding: slice, as: UTF16.self))
    }

    func with(
        _ attribute: ElementAttribute,
        _ value: AccessibilityValue,
    ) -> FakeAccessibilityElement {
        var copy = self
        copy.attributes[attribute] = .value(value)
        return copy
    }

    static func field(
        role: String,
        subrole: String? = nil,
        text: String? = nil,
        cursor: Int? = nil,
    ) -> FakeAccessibilityElement {
        var element = FakeAccessibilityElement(fullText: text)
        element.attributes[.role] = .value(.text(role))
        if let subrole { element.attributes[.subrole] = .value(.text(subrole)) }
        if let text { element.attributes[.value] = .value(.text(text)) }
        let location = cursor ?? text?.utf16.count
        if let location {
            element.attributes[.selectedTextRange] = .value(
                .range(NSRange(location: location, length: 0))
            )
        }
        return element
    }
}
