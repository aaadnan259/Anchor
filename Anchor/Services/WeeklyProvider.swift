import Foundation

struct WeeklyProvider: ScheduleProvider {
    func schedule(habit: Habit, occurrence: Occurrence, on date: Date, calendar: Calendar) -> DueOccurrence? {
        guard case .unscheduled = occurrence.scheduleProvider else { return nil }
        guard isDue(habit: habit, on: date, calendar: calendar) else { return nil }
        return DueOccurrence(occurrence: occurrence, time: nil)
    }
}
