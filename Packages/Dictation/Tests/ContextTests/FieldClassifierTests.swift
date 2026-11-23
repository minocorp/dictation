@testable import Context
import Core
import Testing

internal struct FieldClassifierTests {
    private struct KindCase: Sendable {
        let role: String?
        let isEditable: Bool
        let kind: FieldKind
    }

    private static let kindCases = [
        KindCase(role: "AXTextField", isEditable: false, kind: .singleLine),
        KindCase(role: "AXComboBox", isEditable: false, kind: .singleLine),
        KindCase(role: "AXTextArea", isEditable: false, kind: .multiLine),
        KindCase(role: "AXWebArea", isEditable: false, kind: .webContent),
        KindCase(role: "AXButton", isEditable: false, kind: .noField),
        KindCase(role: "AXMenuItem", isEditable: false, kind: .noField),
        KindCase(role: "AXStaticText", isEditable: true, kind: .other),
        KindCase(role: "AXGroup", isEditable: false, kind: .other),
        KindCase(role: nil, isEditable: false, kind: .other),
    ]

    @Test(arguments: kindCases)
    private func classifiesKind(testCase: KindCase) {
        let kind = FieldClassifier.kind(role: testCase.role, isEditable: testCase.isEditable)
        #expect(kind == testCase.kind)
    }

    private struct SecureCase: Sendable {
        let role: String
        let subrole: String?
        let isSecure: Bool
    }

    private static let secureCases = [
        SecureCase(role: "AXSecureTextField", subrole: nil, isSecure: true),
        SecureCase(role: "AXTextField", subrole: "AXSecureTextField", isSecure: true),
        SecureCase(role: "AXTextField", subrole: "AXSearchField", isSecure: false),
        SecureCase(role: "AXTextArea", subrole: nil, isSecure: false),
    ]

    @Test(arguments: secureCases)
    private func detectsSecureFields(testCase: SecureCase) {
        let found = FieldClassifier.isSecure(role: testCase.role, subrole: testCase.subrole)
        #expect(found == testCase.isSecure)
    }

    private struct SecureInputCase: Sendable {
        let role: String
        let isEditable: AccessibilityRead<Bool>
        let bundleID: String
        let isSecure: Bool
    }

    private static let secureInputCases = [
        SecureInputCase(
            role: "AXTextArea",
            isEditable: .value(true),
            bundleID: "com.apple.Terminal",
            isSecure: true,
        ),
        SecureInputCase(
            role: "AXTextArea",
            isEditable: .value(true),
            bundleID: "com.googlecode.iterm2",
            isSecure: true,
        ),
        SecureInputCase(
            role: "AXTextArea",
            isEditable: .value(true),
            bundleID: "com.example.editor",
            isSecure: false,
        ),
        SecureInputCase(
            role: "AXTextField",
            isEditable: .noValue,
            bundleID: "com.example.editor",
            isSecure: false,
        ),
        SecureInputCase(
            role: "AXTextArea",
            isEditable: .noValue,
            bundleID: "com.example.editor",
            isSecure: true,
        ),
        SecureInputCase(
            role: "AXGroup",
            isEditable: .value(true),
            bundleID: "com.example.editor",
            isSecure: true,
        ),
    ]

    @Test(arguments: secureInputCases)
    private func secureInputBlocksOnlyWhatIsNotProvablyAnEditableField(testCase: SecureInputCase) {
        let traits = FieldTraits(
            role: testCase.role,
            subrole: nil,
            isEditable: testCase.isEditable,
        )
        let found = FieldClassifier.isSecure(
            traits,
            bundleID: testCase.bundleID,
            isSecureInputActive: true,
        )
        #expect(found == testCase.isSecure)
    }

    @Test
    func terminalsAreNotSecureWhenSecureInputIsOff() {
        let traits = FieldTraits(role: "AXTextArea", subrole: nil, isEditable: .value(true))
        let found = FieldClassifier.isSecure(
            traits,
            bundleID: "com.apple.Terminal",
            isSecureInputActive: false,
        )
        #expect(!found)
    }
}
