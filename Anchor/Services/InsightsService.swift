import Foundation

enum InsightsRange: String, CaseIterable, Identifiable {
    case week, month, year

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .week: "Week"
        case .month: "Month"
        case .year: "Year"
        }
    }
}

enum TimeOfDayPeriod: String, CaseIterable, Identifiable {
    case night, morning, afternoon, evening

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .night: "Night"
        case .morning: "Morning"
        case .afternoon: "Afternoon"
        case .evening: "Evening"
        }
    }

    fileprivate var hourRange: Range<Int> {
        switch self {
        case .night: 0..<6
        case .morning: 6..<12
        case .afternoon: 12..<18
        case .evening: 18..<24
        }
    }

    fileprivate static func containing(hour: Int) -> TimeOfDayPeriod {
        allCases.first { $0.hourRange.contains(hour) } ?? .night
    }
}

struct TrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let rate: Double
}

struct TimeOfDaySlice: Identifiable {
    let id = UUID()
    let period: TimeOfDayPeriod
    let count: Int
}

@MainActor
struct InsightsService {
    let completionService: CompletionService
    let streakService: StreakService
    private let calendar: Calendar = .current

    func trend(for habit: Habit, range: InsightsRange, referenceDate: Date = .now) -> [TrendPoint] {
        switch range {
        case .week:
            weeklyTrend(for: habit, referenceDate: referenceDate)
        case .month:
            bucketedTrend(for: habit, component: .month, count: 12, referenceDate: referenceDate)
        case .year:
            bucketedTrend(for: habit, component: .year, count: 5, referenceDate: referenceDate)
        }
    }

    func timeOfDayDistribution(for habit: Habit) -> [TimeOfDaySlice] {
        var counts: [TimeOfDayPeriod: Int] = [:]
        for completion in habit.occurrences.flatMap(\.completions) {
            let hour = calendar.component(.hour, from: completion.completedAt)
            let period = TimeOfDayPeriod.containing(hour: hour)
            counts[period, default: 0] += 1
        }
        return TimeOfDayPeriod.allCases.map { TimeOfDaySlice(period: $0, count: counts[$0] ?? 0) }
    }

    private func weeklyTrend(for habit: Habit, referenceDate: Date) -> [TrendPoint] {
        let weeks = 12
        guard let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start else { return [] }
        let rates = streakService.weeklyCompletionRates(for: habit, weeks: weeks, referenceDate: referenceDate)

        var dates: [Date] = []
        for offset in stride(from: weeks - 1, through: 0, by: -1) {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -offset, to: thisWeekStart) else { continue }
            dates.append(weekStart)
        }
        return zip(dates, rates).map { TrendPoint(date: $0, rate: $1) }
    }

    private func bucketedTrend(for habit: Habit, component: Calendar.Component, count: Int, referenceDate: Date) -> [TrendPoint] {
        guard let thisBucketStart = calendar.dateInterval(of: component, for: referenceDate)?.start else { return [] }

        var points: [TrendPoint] = []
        for offset in stride(from: count - 1, through: 0, by: -1) {
            guard let bucketStart = calendar.date(byAdding: component, value: -offset, to: thisBucketStart),
                  let interval = calendar.dateInterval(of: component, for: bucketStart) else { continue }
            points.append(TrendPoint(date: bucketStart, rate: rate(for: habit, in: interval, referenceDate: referenceDate)))
        }
        return points
    }

    private func rate(for habit: Habit, in interval: DateInterval, referenceDate: Date) -> Double {
        switch habit.frequency {
        case .daily, .weekdays:
            dailyRate(for: habit, in: interval, referenceDate: referenceDate)
        case .timesPerWeek(let target):
            weeklyTargetRate(for: habit, target: target, in: interval, referenceDate: referenceDate)
        }
    }

    private func dailyRate(for habit: Habit, in interval: DateInterval, referenceDate: Date) -> Double {
        let today = calendar.startOfDay(for: referenceDate)
        let habitStart = calendar.startOfDay(for: habit.createdAt)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? interval.end
        var day = max(calendar.startOfDay(for: interval.start), habitStart)
        let end = min(interval.end, tomorrow)

        var dueCount = 0
        var completedCount = 0
        while day < end {
            if DueDateRule.isDue(frequency: habit.frequency, on: day, calendar: calendar) {
                dueCount += 1
                if completionService.isFullyCompleted(habit: habit, on: day) { completedCount += 1 }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return dueCount == 0 ? 0 : Double(completedCount) / Double(dueCount)
    }

    private func weeklyTargetRate(for habit: Habit, target: Int, in interval: DateInterval, referenceDate: Date) -> Double {
        guard target > 0, var weekStart = calendar.dateInterval(of: .weekOfYear, for: interval.start)?.start else { return 0 }
        let today = calendar.startOfDay(for: referenceDate)

        var totalTarget = 0
        var totalCompleted = 0
        while weekStart < interval.end && weekStart <= today {
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else { break }
            if weekInterval.start >= interval.start {
                totalTarget += target
                totalCompleted += min(completionService.completedDayCount(habit: habit, in: weekInterval), target)
            }
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { break }
            weekStart = next
        }
        return totalTarget == 0 ? 0 : Double(totalCompleted) / Double(totalTarget)
    }
}
