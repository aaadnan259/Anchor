import Foundation
import Testing
@testable import Anchor

@Suite("DueDateRule")
struct DueDateRuleTests {
    private let calendar = TestSupport.calendar

    @Test("daily is always due")
    func dailyAlwaysDue() throws {
        let monday = try TestSupport.date(2026, 7, 20)
        let sunday = try TestSupport.date(2026, 7, 26)
        #expect(DueDateRule.isDue(frequency: .daily, on: monday, calendar: calendar))
        #expect(DueDateRule.isDue(frequency: .daily, on: sunday, calendar: calendar))
    }

    @Test("timesPerWeek is always due")
    func timesPerWeekAlwaysDue() throws {
        let sunday = try TestSupport.date(2026, 7, 26)
        #expect(DueDateRule.isDue(frequency: .timesPerWeek(target: 3), on: sunday, calendar: calendar))
    }

    @Test("weekdays only due on selected days")
    func weekdaysOnlySelectedDays() throws {
        let frequency = Frequency.weekdays([.monday, .tuesday, .wednesday, .thursday, .friday])
        let wednesday = try TestSupport.date(2026, 7, 22)
        let saturday = try TestSupport.date(2026, 7, 25)
        let sunday = try TestSupport.date(2026, 7, 26)

        #expect(DueDateRule.isDue(frequency: frequency, on: wednesday, calendar: calendar))
        #expect(!DueDateRule.isDue(frequency: frequency, on: saturday, calendar: calendar))
        #expect(!DueDateRule.isDue(frequency: frequency, on: sunday, calendar: calendar))
    }
}
