import Core

internal enum FieldClassifier {
    private static let secureSubrole = "AXSecureTextField"

    static func isSecure(role: String?, subrole: String?) -> Bool {
        role == AccessibilityRole.secureTextField.rawValue || subrole == secureSubrole
    }

    static func isSecure(
        _ traits: FieldTraits,
        bundleID: String,
        isSecureInputActive: Bool,
    ) -> Bool {
        if isSecure(role: traits.role, subrole: traits.subrole) { return true }
        guard isSecureInputActive else { return false }
        return TerminalApplications.contains(bundleID) || !provesEditableText(traits)
    }

    static func kind(role: String?, isEditable: Bool) -> FieldKind {
        guard let role, let known = AccessibilityRole(rawValue: role) else {
            return .other
        }
        switch known {
        case .textField, .secureTextField, .comboBox: return .singleLine
        case .textArea: return .multiLine
        case .webArea: return .webContent
        case .button, .popUpButton, .menuButton, .menu, .menuBar, .menuBarItem, .menuItem,
            .window, .checkBox, .radioButton, .toolbar, .image, .staticText, .list, .table,
            .outline, .tabGroup, .slider:
            return isEditable ? .other : .noField
        }
    }

    private static func provesEditableText(_ traits: FieldTraits) -> Bool {
        guard let role = traits.role, let known = AccessibilityRole(rawValue: role) else {
            return false
        }
        switch known {
        case .textField, .comboBox: return traits.isEditable.value != false
        case .textArea, .webArea: return traits.isEditable.value == true
        case .secureTextField, .button, .popUpButton, .menuButton, .menu, .menuBar, .menuBarItem,
            .menuItem, .window, .checkBox, .radioButton, .toolbar, .image, .staticText, .list,
            .table, .outline, .tabGroup, .slider:
            return false
        }
    }
}
