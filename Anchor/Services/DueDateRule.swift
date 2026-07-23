import Foundation

enum DueDateRule {
    static func isDue(frequency: Frequency, on date: Date, calendar: Calendar) -> Bool {
        switch frequency {
        case .daily:
            true
        case .weekdays(let days):
            days.contains(Weekday.from(date: date, calendar: calendar))
        case .timesPerWeek:
            true
        }
    }
}
