import AppKit
import SwiftUI

internal struct HistoryAppIcon: View {
    let image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
            } else {
                Image(systemName: "app.dashed")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 28, height: 28)
        .accessibilityHidden(true)
    }
}
