import Foundation

@Observable
@MainActor
final class TodayViewModel {
    private let scheduleService: ScheduleService
    private let completionService: CompletionService
    private let streakService: StreakService
    private let calendar: Calendar

    var expandedHabitIDs: Set<UUID> = []

    init(
        scheduleService: ScheduleService,
        completionService: CompletionService,
        streakService: StreakService,
        calendar: Calendar = .current
    ) {
        self.scheduleService = scheduleService
        self.completionService = completionService
        self.streakService = streakService
        self.calendar = calendar
    }

    struct TodayHabitRow: Identifiable {
        let habit: Habit
        let due: [DueOccurrence]
        let streak: Int
        let subtitle: String?
        let completedCount: Int

        var id: UUID { habit.id }
        var isExpandable: Bool { due.count > 1 }
        var progress: Double { due.isEmpty ? 0 : Double(completedCount) / Double(due.count) }
        var isFullyCompleted: Bool { !due.isEmpty && completedCount == due.count }
    }

    func rows(for habits: [Habit], on date: Date = .now) -> [TodayHabitRow] {
        habits
            .filter { !$0.archived }
            .compactMap { habit -> TodayHabitRow? in
                let due = scheduleService.todaysOccurrences(for: habit, on: date, calendar: calendar)
                guard !due.isEmpty else { return nil }
                let completedCount = due.filter { completionService.isCompleted(occurrence: $0.occurrence, on: date) }.count
                let streak = streakService.currentStreak(for: habit, referenceDate: date)
                let subtitle = subtitleText(for: habit, due: due, completedCount: completedCount, date: date)
                return TodayHabitRow(habit: habit, due: due, streak: streak, subtitle: subtitle, completedCount: completedCount)
            }
            .sorted { $0.habit.displayOrder < $1.habit.displayOrder }
    }

    func overallProgress(for rows: [TodayHabitRow]) -> Double {
        let allDue = rows.flatMap(\.due)
        guard !allDue.isEmpty else { return 0 }
        let completed = rows.reduce(0) { $0 + $1.completedCount }
        return Double(completed) / Double(allDue.count)
    }

    func isCompleted(occurrence: Occurrence, on date: Date = .now) -> Bool {
        completionService.isCompleted(occurrence: occurrence, on: date)
    }

    func toggle(habit: Habit, occurrence: Occurrence, on date: Date = .now) {
        completionService.toggle(habit: habit, occurrence: occurrence, on: date)
    }

    func value(for occurrence: Occurrence, on date: Date = .now) -> Int {
        completionService.value(occurrence: occurrence, on: date)
    }

    func logValue(habit: Habit, occurrence: Occurrence, value: Int, on date: Date = .now) {
        completionService.logValue(habit: habit, occurrence: occurrence, value: value, on: date)
    }

    /// Fill fraction for a quantifiable habit's ring (logged value / target), or nil if `row` isn't quantifiable.
    func quantifiableProgress(for row: TodayHabitRow, on date: Date = .now) -> Double? {
        guard let target = row.habit.targetValue, target > 0, let occurrence = row.due.first?.occurrence else {
            return nil
        }
        return min(Double(value(for: occurrence, on: date)) / Double(target), 1.0)
    }

    func isShielded(habit: Habit, on date: Date = .now) -> Bool {
        completionService.isShielded(habit: habit, on: date)
    }

    func toggleShield(habit: Habit, on date: Date = .now) {
        completionService.toggleShield(habit: habit, on: date)
    }

    func toggleExpanded(_ habitID: UUID) {
        if expandedHabitIDs.contains(habitID) {
            expandedHabitIDs.remove(habitID)
        } else {
            expandedHabitIDs.insert(habitID)
        }
    }

    private func subtitleText(for habit: Habit, due: [DueOccurrence], completedCount: Int, date: Date) -> String? {
        if due.count > 1 {
            return "\(completedCount) of \(due.count) today"
        }
        if case .timesPerWeek = habit.frequency, let progress = streakService.weeklyProgress(for: habit, referenceDate: date) {
            return "\(progress.completed) of \(progress.target) this week"
        }
        return nil
    }
}
