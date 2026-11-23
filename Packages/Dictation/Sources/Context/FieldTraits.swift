internal struct FieldTraits: Sendable {
    let role: String?
    let subrole: String?
    let isEditable: AccessibilityRead<Bool>

    init(role: String?, subrole: String?, isEditable: AccessibilityRead<Bool>) {
        self.role = role
        self.subrole = subrole
        self.isEditable = isEditable
    }

    init(of element: any AccessibilityElement) {
        self.init(
            role: element.string(.role).value,
            subrole: element.string(.subrole).value,
            isEditable: element.flag(.isEditable),
        )
    }
}
