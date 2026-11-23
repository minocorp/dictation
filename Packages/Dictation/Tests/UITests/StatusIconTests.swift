import Core
import Testing
@testable import UI

internal struct StatusIconTests {
    private let granted = PermissionStatus(microphone: .granted, isAccessibilityTrusted: true)

    struct Case {
        let hud: HUDState
        let permissions: PermissionStatus
        let isDownloading: Bool
        let expected: StatusIcon
    }

    static let cases = [
        Case(
            hud: .hidden,
            permissions: PermissionStatus(microphone: .granted, isAccessibilityTrusted: true),
            isDownloading: false,
            expected: .idle,
        ),
        Case(
            hud: .listening,
            permissions: PermissionStatus(microphone: .granted, isAccessibilityTrusted: true),
            isDownloading: true,
            expected: .listening,
        ),
        Case(
            hud: .hidden,
            permissions: PermissionStatus(microphone: .granted, isAccessibilityTrusted: true),
            isDownloading: true,
            expected: .downloading,
        ),
        Case(
            hud: .hidden,
            permissions: PermissionStatus(microphone: .denied, isAccessibilityTrusted: true),
            isDownloading: true,
            expected: .problem,
        ),
        Case(
            hud: .hidden,
            permissions: PermissionStatus(microphone: .granted, isAccessibilityTrusted: false),
            isDownloading: false,
            expected: .problem,
        ),
        Case(
            hud: .problem(.couldNotEdit),
            permissions: PermissionStatus(microphone: .granted, isAccessibilityTrusted: true),
            isDownloading: false,
            expected: .problem,
        ),
    ]

    @Test(arguments: cases)
    func resolvesIconByPriority(testCase: Case) {
        let icon = StatusIcon.resolve(
            hud: testCase.hud,
            permissions: testCase.permissions,
            isDownloading: testCase.isDownloading,
        )
        #expect(icon == testCase.expected)
    }
}
