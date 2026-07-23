import Foundation

struct FixedTimeProvider: ScheduleProvider {
    func schedule(habit: Habit, occurrence: Occurrence, on date: Date, calendar: Calendar) -> DueOccurrence? {
        guard case .fixedTime(let hour, let minute) = occurrence.scheduleProvider else { return nil }
        guard isDue(habit: habit, on: date, calendar: calendar) else { return nil }
        let time = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)
        return DueOccurrence(occurrence: occurrence, time: time)
    }
}
