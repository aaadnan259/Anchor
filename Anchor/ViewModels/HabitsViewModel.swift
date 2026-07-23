import Foundation

@Observable
@MainActor
final class HabitsViewModel {
    private let habitService: HabitService
    private let streakService: StreakService
    private let notificationService: NotificationService
    private let scheduleService: ScheduleService

    init(
        habitService: HabitService,
        streakService: StreakService,
        notificationService: NotificationService,
        scheduleService: ScheduleService
    ) {
        self.habitService = habitService
        self.streakService = streakService
        self.notificationService = notificationService
        self.scheduleService = scheduleService
    }

    func streak(for habit: Habit) -> Int {
        streakService.currentStreak(for: habit)
    }

    func archive(_ habit: Habit) {
        habitService.archive(habit)
        rescheduleNotifications()
    }

    func unarchive(_ habit: Habit) {
        habitService.unarchive(habit)
        rescheduleNotifications()
    }

    func delete(_ habit: Habit) {
        habitService.delete(habit)
        rescheduleNotifications()
    }

    func reorder(_ habits: [Habit]) {
        habitService.reorder(habits)
    }

    private func rescheduleNotifications() {
        let habits = habitService.fetchAll()
        Task {
            await notificationService.rescheduleAll(for: habits, scheduleService: scheduleService)
        }
    }

    func frequencyDescription(for habit: Habit) -> String {
        switch habit.frequency {
        case .daily:
            return "Every day"
        case .weekdays(let days):
            let daySet = Set(days)
            let weekdaySet: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
            if daySet == weekdaySet {
                return "Weekdays"
            }
            return days.sorted().map(\.shortLabel).joined(separator: ", ")
        case .timesPerWeek(let target):
            return "\(target)x per week"
        }
    }
}
