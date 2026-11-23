// AXUIElement is an immutable CF handle that Apple has not marked Sendable.
@preconcurrency import ApplicationServices
import Core
import Foundation

internal struct SystemAccessibilityElement: AccessibilityElement {
    private let element: AXUIElement

    var identity: Int { Int(bitPattern: CFHash(element)) }

    init(_ element: AXUIElement) {
        AXUIElementSetMessagingTimeout(element, AccessibilityTimeout.seconds)
        self.element = element
    }

    func read(_ attribute: ElementAttribute) -> AccessibilityRead<AccessibilityValue> {
        var raw: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(
            element,
            Self.name(of: attribute) as CFString,
            &raw,
        )
        guard error == .success, let raw else { return Self.classify(error) }
        guard let value = Self.convert(raw, for: attribute) else { return .unavailable }
        return .value(value)
    }

    func text(in range: NSRange) -> AccessibilityRead<String> {
        var cfRange = CFRange(location: range.location, length: range.length)
        guard let parameter = AXValueCreate(.cfRange, &cfRange) else { return .unavailable }
        var raw: CFTypeRef?
        let error = AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXStringForRangeParameterizedAttribute as CFString,
            parameter,
            &raw,
        )
        guard error == .success, let text = raw as? String else { return Self.classify(error) }
        return .value(text)
    }

    private static func classify<Value: Sendable>(_ error: AXError) -> AccessibilityRead<Value> {
        let absent: [AXError] = [
            .noValue, .attributeUnsupported, .notImplemented, .parameterizedAttributeUnsupported,
        ]
        return absent.contains(error) ? .noValue : .unavailable
    }

    private static func convert(
        _ raw: CFTypeRef,
        for attribute: ElementAttribute,
    ) -> AccessibilityValue? {
        switch attribute {
        case .role, .subrole, .value, .selectedText:
            (raw as? String).map(AccessibilityValue.text)
        case .selectedTextRange, .markedTextRange:
            range(from: raw).map(AccessibilityValue.range)
        case .isEditable:
            (raw as? Bool).map(AccessibilityValue.flag)
        }
    }

    private static func range(from raw: CFTypeRef) -> NSRange? {
        guard CFGetTypeID(raw) == AXValueGetTypeID() else { return nil }
        var cfRange = CFRange()
        guard AXValueGetValue(unsafeDowncast(raw, to: AXValue.self), .cfRange, &cfRange) else {
            return nil
        }
        return NSRange(location: cfRange.location, length: cfRange.length)
    }

    private static func name(of attribute: ElementAttribute) -> String {
        switch attribute {
        case .role: kAXRoleAttribute
        case .subrole: kAXSubroleAttribute
        case .value: kAXValueAttribute
        case .selectedText: kAXSelectedTextAttribute
        case .selectedTextRange: kAXSelectedTextRangeAttribute
        case .markedTextRange: "AXMarkedTextRange"
        case .isEditable: "AXEditable"
        }
    }
}
