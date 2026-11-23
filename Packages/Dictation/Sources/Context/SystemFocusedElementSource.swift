import ApplicationServices
import Core

internal struct SystemFocusedElementSource: FocusedElementSource {
    func focusedElement(ofPID pid: Int32) -> AccessibilityRead<any AccessibilityElement> {
        let application = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(application, AccessibilityTimeout.seconds)
        var raw: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(
            application,
            kAXFocusedUIElementAttribute as CFString,
            &raw,
        )
        if error == .success {
            guard let raw, CFGetTypeID(raw) == AXUIElementGetTypeID() else { return .unavailable }
            return .value(SystemAccessibilityElement(unsafeDowncast(raw, to: AXUIElement.self)))
        }
        let absent: [AXError] = [.noValue, .attributeUnsupported, .notImplemented]
        return absent.contains(error) ? .noValue : .unavailable
    }
}
