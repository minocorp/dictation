@testable import Context

internal struct FakeFocusedElementSource: FocusedElementSource {
    var result: AccessibilityRead<FakeAccessibilityElement>

    func focusedElement(ofPID pid: Int32) -> AccessibilityRead<any AccessibilityElement> {
        switch result {
        case .value(let element): .value(element)
        case .noValue: .noValue
        case .unavailable: .unavailable
        }
    }
}
