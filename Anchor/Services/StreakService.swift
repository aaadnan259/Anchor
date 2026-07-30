import Foundation

enum DayCompletionState: Equatable {
    case completed
    case shielded
    case partial
    case missed
    case notDue
}

@MainActor
struct StreakService {
    let completionService: CompletionService
    private let calendar: Calendar = .current

    func currentStreak(for habit: Habit, referenceDate: Date = .now) -> Int {
        switch habit.frequency {
        case .daily, .weekdays:
            currentDailyStreak(for: habit, referenceDate: referenceDate)
        case .timesPerWeek(let target):
            currentWeeklyStreak(for: habit, target: target, referenceDate: referenceDate)
        }
    }

    func bestStreak(for habit: Habit, referenceDate: Date = .now) -> Int {
        switch habit.frequency {
        case .daily, .weekdays:
            bestDailyStreak(for: habit, referenceDate: referenceDate)
        case .timesPerWeek(let target):
            bestWeeklyStreak(for: habit, target: target, referenceDate: referenceDate)
        }
    }

    func completionRate(for habit: Habit, weeks: Int = 4, referenceDate: Date = .now) -> Double {
        guard let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start,
              let rangeStart = calendar.date(byAdding: .weekOfYear, value: -(weeks - 1), to: thisWeekStart) else {
            return 0
        }

        switch habit.frequency {
        case .daily, .weekdays:
            var dueCount = 0
            var completedCount = 0
            var day = rangeStart
            let today = calendar.startOfDay(for: referenceDate)
            while day <= today {
                if isDue(habit: habit, on: day) {
                    dueCount += 1
                    if completionService.isFullyCompleted(habit: habit, on: day) { completedCount += 1 }
                }
                guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
            return dueCount == 0 ? 0 : Double(completedCount) / Double(dueCount)

        case .timesPerWeek(let target):
            var totalTarget = 0
            var totalCompleted = 0
            var weekStart = rangeStart
            while weekStart <= thisWeekStart {
                totalTarget += target
                totalCompleted += min(completionCount(for: habit, weekStarting: weekStart), target)
                guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { break }
                weekStart = next
            }
            return totalTarget == 0 ? 0 : Double(totalCompleted) / Double(totalTarget)
        }
    }

    func weeklyProgress(for habit: Habit, referenceDate: Date = .now) -> (completed: Int, target: Int)? {
        guard case .timesPerWeek(let target) = habit.frequency,
              let weekStart = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start else {
            return nil
        }
        return (completionCount(for: habit, weekStarting: weekStart), target)
    }

    func weeklyCompletionRates(for habit: Habit, weeks: Int = 4, referenceDate: Date = .now) -> [Double] {
        guard let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start else { return [] }
        var rates: [Double] = []
        for offset in stride(from: weeks - 1, through: 0, by: -1) {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -offset, to: thisWeekStart) else { continue }
            switch habit.frequency {
            case .daily, .weekdays:
                rates.append(dailyRate(for: habit, weekStarting: weekStart, referenceDate: referenceDate))
            case .timesPerWeek(let target):
                let count = completionCount(for: habit, weekStarting: weekStart)
                rates.append(target == 0 ? 0 : min(Double(count) / Double(target), 1))
            }
        }
        return rates
    }

    func dailyHistory(for habit: Habit, days: Int = 112, referenceDate: Date = .now) -> [DayCompletionState] {
        let today = calendar.startOfDay(for: referenceDate)
        let habitStart = calendar.startOfDay(for: habit.createdAt)
        let rangeStart = dailyHistoryStartDate(days: days, referenceDate: referenceDate)

        var history: [DayCompletionState] = []
        var day = rangeStart
        while day <= today {
            if day < habitStart || !isDue(habit: habit, on: day) {
                history.append(.notDue)
            } else {
                let completedCount = habit.occurrences.filter { completionService.isCompleted(occurrence: $0, on: day) }.count
                if completedCount == habit.occurrences.count && completedCount > 0 {
                    history.append(.completed)
                } else if completionService.isShielded(habit: habit, on: day) {
                    history.append(.shielded)
                } else if completedCount == 0 {
                    history.append(hasLoggedProgress(habit: habit, on: day) ? .partial : .missed)
                } else {
                    history.append(.partial)
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return history
    }

    func dailyHistoryStartDate(days: Int = 112, referenceDate: Date = .now) -> Date {
        let today = calendar.startOfDay(for: referenceDate)
        return calendar.date(byAdding: .day, value: -(days - 1), to: today) ?? today
    }

    private func isDue(habit: Habit, on date: Date) -> Bool {
        DueDateRule.isDue(frequency: habit.frequency, on: date, calendar: calendar)
    }

    /// True if any occurrence has a logged value below its completion threshold (e.g. a quantifiable
    /// habit logged under target) — distinguishes "attempted but short" from "did nothing" in `dailyHistory`.
    private func hasLoggedProgress(habit: Habit, on day: Date) -> Bool {
        habit.occurrences.contains { completionService.value(occurrence: $0, on: day) > 0 }
    }

    private func completionCount(for habit: Habit, weekStarting weekStart: Date) -> Int {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else { return 0 }
        return completionService.completedDayCount(habit: habit, in: weekInterval)
    }

    private func dailyRate(for habit: Habit, weekStarting weekStart: Date, referenceDate: Date) -> Double {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else { return 0 }
        var dueCount = 0
        var completedCount = 0
        var day = weekInterval.start
        let today = calendar.startOfDay(for: referenceDate)
        while day < weekInterval.end && day <= today {
            if isDue(habit: habit, on: day) {
                dueCount += 1
                if completionService.isFullyCompleted(habit: habit, on: day) { completedCount += 1 }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return dueCount == 0 ? 0 : Double(completedCount) / Double(dueCount)
    }

    private func currentDailyStreak(for habit: Habit, referenceDate: Date) -> Int {
        var streak = 0
        var day = calendar.startOfDay(for: referenceDate)
        var isFirstDayChecked = true
        let habitStart = calendar.startOfDay(for: habit.createdAt)

        while day >= habitStart {
            if isDue(habit: habit, on: day) {
                if completionService.isFullyCompleted(habit: habit, on: day) {
                    streak += 1
                } else if completionService.isShielded(habit: habit, on: day) {
                    // Shielded day: doesn't count toward the streak, but doesn't break it either.
                } else if isFirstDayChecked {
                    // Reference date is due but not finished yet; don't break the streak, just don't count it.
                } else {
                    break
                }
            }
            isFirstDayChecked = false
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    private func bestDailyStreak(for habit: Habit, referenceDate: Date) -> Int {
        var best = 0
        var current = 0
        var day = calendar.startOfDay(for: habit.createdAt)
        let today = calendar.startOfDay(for: referenceDate)

        while day <= today {
            if isDue(habit: habit, on: day) {
                if completionService.isFullyCompleted(habit: habit, on: day) {
                    current += 1
                    best = max(best, current)
                } else if completionService.isShielded(habit: habit, on: day) {
                    // Shielded day: carry the current run forward unchanged.
                } else {
                    current = 0
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return best
    }

    private func currentWeeklyStreak(for habit: Habit, target: Int, referenceDate: Date) -> Int {
        var streak = 0
        guard var weekStart = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start,
              let habitStartWeek = calendar.dateInterval(of: .weekOfYear, for: habit.createdAt)?.start else {
            return 0
        }
        var isFirstWeekChecked = true

        while weekStart >= habitStartWeek {
            let count = completionCount(for: habit, weekStarting: weekStart)
            if count >= target {
                streak += 1
            } else if isFirstWeekChecked {
                // Current week still in progress; don't break the streak, just don't count it yet.
            } else {
                break
            }
            isFirstWeekChecked = false
            guard let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart) else { break }
            weekStart = previous
        }
        return streak
    }

    private func bestWeeklyStreak(for habit: Habit, target: Int, referenceDate: Date) -> Int {
        var best = 0
        var current = 0
        guard var weekStart = calendar.dateInterval(of: .weekOfYear, for: habit.createdAt)?.start,
              let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start else {
            return 0
        }

        while weekStart <= currentWeekStart {
            if completionCount(for: habit, weekStarting: weekStart) >= target {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { break }
            weekStart = next
        }
        return best
    }
}
