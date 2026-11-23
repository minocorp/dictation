import SwiftUI

internal struct HistorySectionHeader: View {
    let title: HistorySection.Title

    var body: some View {
        switch title {
        case .today: Text(UIString.historyToday)
        case .yesterday: Text(UIString.historyYesterday)
        case .date(let date): Text(date, format: .dateTime.year().month().day().weekday())
        }
    }
}
