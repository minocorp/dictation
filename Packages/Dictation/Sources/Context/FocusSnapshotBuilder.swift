import Core
import Foundation

internal enum FocusSnapshotBuilder {
    static func build(
        target: TargetApp,
        focus: AccessibilityRead<any AccessibilityElement>,
        isSecureInputActive: Bool,
    ) -> FocusSnapshot {
        guard case .value(let element) = focus else {
            return FocusSnapshot(
                target: target,
                fieldKind: .other,
                fieldID: nil,
                isSecure: isSecureInputActive,
                isComposing: false,
                textBefore: nil,
            )
        }
        let traits = FieldTraits(of: element)
        let isSecure = FieldClassifier.isSecure(
            traits,
            bundleID: target.bundleID,
            isSecureInputActive: isSecureInputActive,
        )
        let kind = FieldClassifier.kind(
            role: traits.role,
            isEditable: traits.isEditable.value ?? false,
        )
        let readsText = !isSecure && kind != .noField
        return FocusSnapshot(
            target: target,
            fieldKind: kind,
            fieldID: element.identity,
            isSecure: isSecure,
            isComposing: readsText && isComposing(element),
            textBefore: readsText ? TextBeforeReader.read(from: element) : nil,
        )
    }

    static func isSecure(
        target: TargetApp,
        focus: AccessibilityRead<any AccessibilityElement>,
        isSecureInputActive: Bool,
    ) -> Bool {
        guard case .value(let element) = focus else { return isSecureInputActive }
        return FieldClassifier.isSecure(
            FieldTraits(of: element),
            bundleID: target.bundleID,
            isSecureInputActive: isSecureInputActive,
        )
    }

    private static func isComposing(_ element: any AccessibilityElement) -> Bool {
        guard case .value(let marked) = element.range(.markedTextRange) else { return false }
        return marked.length > 0
    }
}
