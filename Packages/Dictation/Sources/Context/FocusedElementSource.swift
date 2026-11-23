internal protocol FocusedElementSource: Sendable {
    func focusedElement(ofPID pid: Int32) -> AccessibilityRead<any AccessibilityElement>
}
