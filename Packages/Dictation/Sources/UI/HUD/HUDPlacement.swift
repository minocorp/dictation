public import CoreGraphics

public enum HUDPlacement {
    static let bottomInset: CGFloat = 20

    public static func frame(size: CGSize, on display: DisplayGeometry) -> CGRect {
        let centered = display.frame.midX - size.width / 2
        let lowest = display.visibleFrame.minX
        let highest = display.visibleFrame.maxX - size.width
        let x = highest >= lowest ? min(max(centered, lowest), highest) : lowest
        let y = display.visibleFrame.minY + bottomInset
        return CGRect(origin: CGPoint(x: x, y: y), size: size)
    }

    public static func display(
        for windowFrame: CGRect?,
        among displays: [DisplayGeometry],
    ) -> DisplayGeometry? {
        guard let windowFrame else { return displays.first }
        let overlaps = displays.map { overlapArea(windowFrame, $0.frame) }
        guard let largest = overlaps.max(), largest > 0,
            let index = overlaps.firstIndex(of: largest)
        else { return displays.first }
        return displays[index]
    }

    private static func overlapArea(_ first: CGRect, _ second: CGRect) -> CGFloat {
        let overlap = first.intersection(second)
        return overlap.isNull ? 0 : overlap.width * overlap.height
    }
}
