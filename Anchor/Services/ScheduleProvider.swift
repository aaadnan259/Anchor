import Foundation

struct DueOccurrence: Equatable {
    let occurrence: Occurrence
    let time: Date?

    static func == (lhs: DueOccurrence, rhs: DueOccurrence) -> Bool {
        lhs.occurrence.id == rhs.occurrence.id && lhs.time == rhs.time
    }
}

protocol ScheduleProvider {
    func schedule(habit: Habit, occurrence: Occurrence, on date: Date, calendar: Calendar) -> DueOccurrence?
}

extension ScheduleProvider {
    func isDue(habit: Habit, on date: Date, calendar: Calendar) -> Bool {
        DueDateRule.isDue(frequency: habit.frequency, on: date, calendar: calendar)
    }
}
