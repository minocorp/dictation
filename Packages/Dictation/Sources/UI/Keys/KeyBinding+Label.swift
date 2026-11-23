public import Core
import Foundation

extension KeyBinding {
    public var label: String {
        modifierPrefix + triggerLabel
    }

    private var modifierPrefix: String {
        let ordered: [(KeyModifiers, String)] = [
            (.function, "fn "), (.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘"),
        ]
        return ordered.filter { modifiers.contains($0.0) }.map(\.1).joined()
    }

    private var triggerLabel: String {
        switch trigger {
        case .key(let code): Self.keyLabel(code)
        case .mouseButton(let index): Self.mouseLabel(index)
        }
    }

    private static func keyLabel(_ code: UInt16) -> String {
        guard let modifier = KeyNames.modifier(forKeyCode: code) else {
            return KeyNames.regular[code] ?? "#\(code)"
        }
        let name = modifierName(modifier)
        if KeyNames.rightSideKeyCodes.contains(code) {
            return UIString.string(UIString.keyRight) + " " + name
        }
        if KeyNames.leftSideKeyCodes.contains(code) {
            return UIString.string(UIString.keyLeft) + " " + name
        }
        return name
    }

    private static func mouseLabel(_ index: Int) -> String {
        UIString.string(UIString.keyMouseButton) + " " + (index + 1).formatted()
    }

    private static func modifierName(_ modifier: KeyModifiers) -> String {
        let names: [(KeyModifiers, String)] = [
            (.command, "Command"), (.shift, "Shift"), (.option, "Option"),
            (.control, "Control"), (.function, "fn"),
        ]
        return names.first { $0.0 == modifier }?.1 ?? "fn"
    }
}
