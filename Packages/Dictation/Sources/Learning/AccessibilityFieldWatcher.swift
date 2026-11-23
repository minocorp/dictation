// AXUIElement is an immutable CF handle that Apple has not marked Sendable.
@preconcurrency import ApplicationServices
import Core

internal struct AccessibilityFieldWatcher: FieldWatching {
    private static let maxWatchedUnits = 200_000

    func watchFocusedField(ofPID pid: Int32) async -> (any WatchedField)? {
        let application = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(application, AccessibilityTimeout.seconds)
        guard let field = Self.focusedField(of: application) else { return nil }
        guard !Self.isSecure(field), let text = Self.value(of: field),
            text.utf16.count <= Self.maxWatchedUnits
        else { return nil }
        return AccessibilityFieldSession(pid: pid, application: application, field: field)
    }

    static func focusedField(of application: AXUIElement) -> AXUIElement? {
        var raw: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(
            application,
            kAXFocusedUIElementAttribute as CFString,
            &raw,
        )
        guard error == .success, let raw, CFGetTypeID(raw) == AXUIElementGetTypeID() else {
            return nil
        }
        let element = unsafeDowncast(raw, to: AXUIElement.self)
        AXUIElementSetMessagingTimeout(element, AccessibilityTimeout.seconds)
        return element
    }

    static func isSecure(_ field: AXUIElement) -> Bool {
        let role = string(kAXRoleAttribute, of: field)
        let subrole = string(kAXSubroleAttribute, of: field)
        return role == "AXSecureTextField" || subrole == "AXSecureTextField"
    }

    static func value(of field: AXUIElement) -> String? {
        string(kAXValueAttribute, of: field)
    }

    private static func string(_ attribute: String, of element: AXUIElement) -> String? {
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &raw) == .success else {
            return nil
        }
        return raw as? String
    }
}
