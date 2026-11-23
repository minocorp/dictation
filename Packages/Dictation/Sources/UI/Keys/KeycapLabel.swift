import SwiftUI

internal struct KeycapLabel: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(.system(size: 12))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
    }
}
