public import CoreGraphics

public struct DisplayGeometry: Hashable, Sendable {
    public let frame: CGRect
    public let visibleFrame: CGRect

    public init(frame: CGRect, visibleFrame: CGRect) {
        self.frame = frame
        self.visibleFrame = visibleFrame
    }
}
