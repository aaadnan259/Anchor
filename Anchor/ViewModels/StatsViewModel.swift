import Foundation

@Observable
@MainActor
final class StatsViewModel {
    private let streakService: StreakService

    init(streakService: StreakService) {
        self.streakService = streakService
    }

    struct HabitStats: Identifiable {
        let habit: Habit
        let currentStreak: Int
        let bestStreak: Int
        let completionRate: Double
        let weeklyRates: [Double]
        let history: [DayCompletionState]

        var id: UUID { habit.id }
    }

    func stats(for habits: [Habit]) -> [HabitStats] {
        habits
            .filter { !$0.archived }
            .map { habit in
                HabitStats(
                    habit: habit,
                    currentStreak: streakService.currentStreak(for: habit),
                    bestStreak: streakService.bestStreak(for: habit),
                    completionRate: streakService.completionRate(for: habit),
                    weeklyRates: streakService.weeklyCompletionRates(for: habit),
                    history: streakService.dailyHistory(for: habit)
                )
            }
            .sorted { $0.habit.displayOrder < $1.habit.displayOrder }
    }
}
