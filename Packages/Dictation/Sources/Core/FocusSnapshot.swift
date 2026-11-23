public struct FocusSnapshot: Hashable, Sendable {
    public let target: TargetApp
    public let fieldKind: FieldKind
    public let fieldID: Int?
    public let isSecure: Bool
    public let isComposing: Bool
    public let textBefore: String?

    public init(
        target: TargetApp,
        fieldKind: FieldKind,
        fieldID: Int?,
        isSecure: Bool,
        isComposing: Bool,
        textBefore: String?,
    ) {
        self.target = target
        self.fieldKind = fieldKind
        self.fieldID = fieldID
        self.isSecure = isSecure
        self.isComposing = isComposing
        self.textBefore = textBefore
    }
}
