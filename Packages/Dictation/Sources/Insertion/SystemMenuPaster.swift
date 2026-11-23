// AXUIElement is an immutable CF handle that Apple has not marked Sendable.
@preconcurrency import ApplicationServices
import Core
import Foundation

internal struct SystemMenuPaster: MenuPaster {
    private static let pasteCharacter = "V"
    private static let commandOnlyModifiers = 0

    func pressPaste(pid: Int32) -> Bool {
        let application = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(application, AccessibilityTimeout.seconds)
        guard let menuBar = Self.element(application, kAXMenuBarAttribute) else { return false }
        for menuBarItem in Self.children(of: menuBar) {
            guard let menu = Self.children(of: menuBarItem).first else { continue }
            for item in Self.children(of: menu) where Self.isPaste(item) {
                return Self.isEnabled(item) && Self.press(item)
            }
        }
        return false
    }

    private static func isPaste(_ item: AXUIElement) -> Bool {
        guard
            let character = attribute(item, kAXMenuItemCmdCharAttribute) as? String,
            let modifiers = attribute(item, kAXMenuItemCmdModifiersAttribute) as? Int
        else { return false }
        return character.uppercased() == pasteCharacter && modifiers == commandOnlyModifiers
    }

    private static func isEnabled(_ item: AXUIElement) -> Bool {
        (attribute(item, kAXEnabledAttribute) as? Bool) ?? false
    }

    private static func press(_ item: AXUIElement) -> Bool {
        AXUIElementPerformAction(item, kAXPressAction as CFString) == .success
    }

    private static func children(of element: AXUIElement) -> [AXUIElement] {
        (attribute(element, kAXChildrenAttribute) as? [AXUIElement]) ?? []
    }

    private static func element(_ parent: AXUIElement, _ name: String) -> AXUIElement? {
        guard let raw = attribute(parent, name), CFGetTypeID(raw) == AXUIElementGetTypeID() else {
            return nil
        }
        return unsafeDowncast(raw, to: AXUIElement.self)
    }

    private static func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        AXUIElementSetMessagingTimeout(element, AccessibilityTimeout.seconds)
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &raw) == .success else {
            return nil
        }
        return raw
    }
}
