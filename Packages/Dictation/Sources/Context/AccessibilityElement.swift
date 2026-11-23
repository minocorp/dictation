import Foundation

internal protocol AccessibilityElement: Sendable {
    var identity: Int { get }
    func read(_ attribute: ElementAttribute) -> AccessibilityRead<AccessibilityValue>
    func text(in range: NSRange) -> AccessibilityRead<String>
}
