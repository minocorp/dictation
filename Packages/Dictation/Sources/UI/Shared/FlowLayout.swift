import SwiftUI

internal struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(in: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout (),
    ) {
        let arrangement = arrange(in: bounds.width, subviews: subviews)
        for (subview, origin) in zip(subviews, arrangement.origins) {
            subview.place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                proposal: .unspecified,
            )
        }
    }

    private func arrange(
        in width: CGFloat,
        subviews: Subviews,
    ) -> (origins: [CGPoint], size: CGSize) {
        var origins: [CGPoint] = []
        var cursor = CGPoint.zero
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if cursor.x > 0, cursor.x + size.width > width {
                cursor = CGPoint(x: 0, y: cursor.y + rowHeight + spacing)
                rowHeight = 0
            }
            origins.append(cursor)
            cursor.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, cursor.x - spacing)
        }
        return (origins, CGSize(width: widest, height: cursor.y + rowHeight))
    }
}
