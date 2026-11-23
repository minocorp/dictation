import Core
import Foundation

internal struct HistorySection: Identifiable, Equatable {
    enum Title: Equatable {
        case today
        case yesterday
        case date(Date)
    }

    let day: Date
    let items: [HistoryItem]

    var id: Date { day }

    func title(now: Date, calendar: Calendar) -> Title {
        if calendar.isDate(day, inSameDayAs: now) { return .today }
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
            calendar.isDate(day, inSameDayAs: yesterday)
        else { return .date(day) }
        return .yesterday
    }

    static func group(_ items: [HistoryItem], calendar: Calendar) -> [HistorySection] {
        let byDay = Dictionary(grouping: items) { calendar.startOfDay(for: $0.date) }
        return byDay.keys.sorted(by: >)
            .map { day in
                HistorySection(day: day, items: (byDay[day] ?? []).sorted { $0.date > $1.date })
            }
    }
}
