import Foundation

@Observable
@MainActor
final class HabitInsightsViewModel {
    private let insightsService: InsightsService
    private let streakService: StreakService
    private let completionService: CompletionService

    var selectedRange: InsightsRange = .week

    init(insightsService: InsightsService, streakService: StreakService, completionService: CompletionService) {
        self.insightsService = insightsService
        self.streakService = streakService
        self.completionService = completionService
    }

    func trendPoints(for habit: Habit) -> [TrendPoint] {
        insightsService.trend(for: habit, range: selectedRange)
    }

    func timeOfDaySlices(for habit: Habit) -> [TimeOfDaySlice] {
        insightsService.timeOfDayDistribution(for: habit)
    }

    func dailyHistory(for habit: Habit) -> [DayCompletionState] {
        streakService.dailyHistory(for: habit)
    }

    func dayCompletionState(for habit: Habit, on date: Date) -> DayCompletionState {
        streakService.dayCompletionState(for: habit, on: date)
    }

    func isShielded(habit: Habit, on day: Date) -> Bool {
        completionService.isShielded(habit: habit, on: day)
    }

    func toggleShield(habit: Habit, on day: Date) {
        completionService.toggleShield(habit: habit, on: day)
    }

    func shieldedDays(for habit: Habit) -> [Date] {
        habit.shields.map(\.day).sorted(by: >)
    }
}
