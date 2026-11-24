import SwiftUI

internal struct LicensesSheet: View {
    let notices: [LicenseNotice]
    let close: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            List(notices) { notice in
                LabeledContent {
                    Text(verbatim: notice.license)
                } label: {
                    Text(verbatim: notice.name)
                }
            }
            HStack {
                Spacer()
                Button(UIString.commonDone, action: close)
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 420, height: 360)
    }
}
