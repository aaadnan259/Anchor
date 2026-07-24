import Foundation

@Observable
@MainActor
final class HabitsViewModel {
    private let habitService: HabitService
    private let streakService: StreakService
    private let notificationService: NotificationService
    private let scheduleService: ScheduleService
    private let completionService: CompletionService
    private let smartRemindersEnabled: Bool

    init(
        habitService: HabitService,
        streakService: StreakService,
        notificationService: NotificationService,
        scheduleService: ScheduleService,
        completionService: CompletionService,
        smartRemindersEnabled: Bool
    ) {
        self.habitService = habitService
        self.streakService = streakService
        self.notificationService = notificationService
        self.scheduleService = scheduleService
        self.completionService = completionService
        self.smartRemindersEnabled = smartRemindersEnabled
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

    func duplicate(_ habit: Habit) {
        habitService.duplicate(habit)
        rescheduleNotifications()
    }

    func reorder(_ habits: [Habit]) {
        habitService.reorder(habits)
    }

    private func rescheduleNotifications() {
        let habits = habitService.fetchAll()
        Task {
            await notificationService.rescheduleAll(
                for: habits,
                scheduleService: scheduleService,
                completionService: completionService,
                smartRemindersEnabled: smartRemindersEnabled
            )
        }
    }

    func frequencyDescription(for habit: Habit) -> String {
        habit.frequency.displayName
    }
}
