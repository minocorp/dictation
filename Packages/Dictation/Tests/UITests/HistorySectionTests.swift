import Core
import Foundation
import Testing
@testable import UI

internal struct HistorySectionTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let now = UIFixtures.referenceDate

    private func date(daysAgo days: Int, hoursAgo hours: Int = 0) -> Date {
        let shifted = calendar.date(byAdding: .day, value: -days, to: now) ?? now
        return shifted.addingTimeInterval(-Double(hours) * 3_600)
    }

    @Test
    func groupsByDayNewestFirst() {
        let items = [
            UIFixtures.item(date: date(daysAgo: 2)),
            UIFixtures.item(date: date(daysAgo: 0)),
            UIFixtures.item(date: date(daysAgo: 0, hoursAgo: 1)),
        ]
        let sections = HistorySection.group(items, calendar: calendar)
        #expect(sections.count == 2)
        #expect(sections[0].items.count == 2)
        #expect(sections[0].items[0].date > sections[0].items[1].date)
        #expect(sections[0].day > sections[1].day)
    }

    @Test
    func titlesTodayYesterdayAndOlderDays() {
        let sections = HistorySection.group(
            [
                UIFixtures.item(date: date(daysAgo: 0)),
                UIFixtures.item(date: date(daysAgo: 1)),
                UIFixtures.item(date: date(daysAgo: 5)),
            ],
            calendar: calendar,
        )
        #expect(sections[0].title(now: now, calendar: calendar) == .today)
        #expect(sections[1].title(now: now, calendar: calendar) == .yesterday)
        guard case .date = sections[2].title(now: now, calendar: calendar) else {
            Issue.record("expected a dated title")
            return
        }
    }

    @Test
    func noItemsMeansNoSections() {
        #expect(HistorySection.group([], calendar: calendar).isEmpty)
    }
}
