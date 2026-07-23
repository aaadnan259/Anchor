import Foundation

@Observable
@MainActor
final class HabitInsightsViewModel {
    private let insightsService: InsightsService

    var selectedRange: InsightsRange = .week

    init(insightsService: InsightsService) {
        self.insightsService = insightsService
    }

    func trendPoints(for habit: Habit) -> [TrendPoint] {
        insightsService.trend(for: habit, range: selectedRange)
    }

    func timeOfDaySlices(for habit: Habit) -> [TimeOfDaySlice] {
        insightsService.timeOfDayDistribution(for: habit)
    }
}
