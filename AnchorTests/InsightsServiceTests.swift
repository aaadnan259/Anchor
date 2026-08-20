import Foundation
import SwiftData
import Testing
@testable import Anchor

@MainActor
@Suite("InsightsService")
struct InsightsServiceTests {
    // Matches StreakServiceTests: InsightsService does real local day/hour math
    // (via CompletionService/StreakService), so fixtures use Calendar.current
    // rather than TestSupport's fixed UTC calendar used by schedule-related tests.
    private let calendar = Calendar.current

    private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }

    private func dateTime(_ year: Int, _ month: Int, _ day: Int, hour: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)))
    }

    private func makeDailyHabit(createdAt: Date) -> (Habit, Occurrence) {
        let habit = Habit(name: "Prayer", icon: "moon.stars.fill", accentColor: .violet, frequency: .daily, createdAt: createdAt, displayOrder: 0)
        let occurrence = Occurrence(title: "Prayer", displayOrder: 0, scheduleProvider: .unscheduled)
        habit.occurrences = [occurrence]
        return (habit, occurrence)
    }

    /// Wires a Completion directly into the in-memory relationship graph, bypassing
    /// CompletionService/ModelContext entirely — InsightsService only ever reads this array.
    private func complete(_ occurrence: Occurrence, habit: Habit, on day: Date, at completedAt: Date? = nil) {
        let completion = Completion(habit: habit, occurrence: occurrence, day: calendar.startOfDay(for: day), completedAt: completedAt ?? day)
        occurrence.completions.append(completion)
    }

    private func makeInsightsService() throws -> InsightsService {
        let completionService = CompletionService(context: try TestSupport.makeContext())
        return InsightsService(completionService: completionService, streakService: StreakService(completionService: completionService))
    }

    @Test(".week trend returns 12 points, with the most recent week reflecting known completions")
    func weekTrendReturnsExpectedPoints() throws {
        let referenceDate = try date(2026, 7, 22)
        let habitStart = try #require(calendar.date(byAdding: .weekOfYear, value: -12, to: referenceDate))
        let (habit, occurrence) = makeDailyHabit(createdAt: habitStart)
        let insightsService = try makeInsightsService()

        let thisWeek = try #require(calendar.dateInterval(of: .weekOfYear, for: referenceDate))
        var day = thisWeek.start
        while day < thisWeek.end && day <= referenceDate {
            complete(occurrence, habit: habit, on: day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }

        let points = insightsService.trend(for: habit, range: .week, referenceDate: referenceDate)

        #expect(points.count == 12)
        #expect(points.last?.date == thisWeek.start)
        #expect(points.last?.rate == 1.0)
        #expect(points.dropLast().allSatisfy { $0.rate == 0 })

        let expectedFirstWeek = try #require(calendar.date(byAdding: .weekOfYear, value: -11, to: thisWeek.start))
        #expect(points.first?.date == expectedFirstWeek)
    }

    @Test(".month trend correctly buckets completions across a month boundary")
    func monthTrendBucketsAcrossMonthBoundary() throws {
        let referenceDate = try date(2026, 8, 5)
        let habitStart = try date(2025, 6, 1)
        let (habit, occurrence) = makeDailyHabit(createdAt: habitStart)
        let insightsService = try makeInsightsService()

        var day = try date(2026, 7, 1)
        let augustFirst = try date(2026, 8, 1)
        while day < augustFirst {
            complete(occurrence, habit: habit, on: day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        for d in 1...3 {
            complete(occurrence, habit: habit, on: try date(2026, 8, d))
        }

        let points = insightsService.trend(for: habit, range: .month, referenceDate: referenceDate)
        #expect(points.count == 12)

        let july = try date(2026, 7, 1)
        let august = try date(2026, 8, 1)
        let julyPoint = try #require(points.first { calendar.isDate($0.date, equalTo: july, toGranularity: .month) })
        let augustPoint = try #require(points.first { calendar.isDate($0.date, equalTo: august, toGranularity: .month) })

        #expect(julyPoint.rate == 1.0)
        #expect(abs(augustPoint.rate - (3.0 / 5.0)) < 0.0001)
    }

    @Test(".year trend buckets completions into the correct year and handles a year before the habit existed")
    func yearTrendBucketsAcrossYearBoundary() throws {
        let habitStart = try date(2026, 1, 1)
        let referenceDate = try date(2026, 1, 5)
        let (habit, occurrence) = makeDailyHabit(createdAt: habitStart)
        let insightsService = try makeInsightsService()

        for d in 1...5 {
            complete(occurrence, habit: habit, on: try date(2026, 1, d))
        }

        let points = insightsService.trend(for: habit, range: .year, referenceDate: referenceDate)
        #expect(points.count == 5)

        let thisYearPoint = try #require(points.last)
        #expect(thisYearPoint.rate == 1.0)

        let lastYearPoint = points[points.count - 2]
        #expect(lastYearPoint.rate == 0)
    }

    @Test("time-of-day distribution buckets completions at exact boundary hours correctly")
    func timeOfDayBucketsBoundaryHours() throws {
        let day = try date(2026, 7, 22)
        let (habit, occurrence) = makeDailyHabit(createdAt: day)
        let insightsService = try makeInsightsService()

        complete(occurrence, habit: habit, on: day, at: try dateTime(2026, 7, 22, hour: 0))
        complete(occurrence, habit: habit, on: day, at: try dateTime(2026, 7, 22, hour: 6))
        complete(occurrence, habit: habit, on: day, at: try dateTime(2026, 7, 22, hour: 12))
        complete(occurrence, habit: habit, on: day, at: try dateTime(2026, 7, 22, hour: 18))

        let slices = insightsService.timeOfDayDistribution(for: habit)
        func count(_ period: TimeOfDayPeriod) -> Int {
            slices.first { $0.period == period }?.count ?? -1
        }

        #expect(count(.night) == 1)
        #expect(count(.morning) == 1)
        #expect(count(.afternoon) == 1)
        #expect(count(.evening) == 1)
    }

    @Test("time-of-day distribution returns four zero-count slices when there are no completions")
    func timeOfDayZeroCompletions() throws {
        let day = try date(2026, 7, 22)
        let (habit, _) = makeDailyHabit(createdAt: day)
        let insightsService = try makeInsightsService()

        let slices = insightsService.timeOfDayDistribution(for: habit)

        #expect(slices.count == 4)
        #expect(slices.allSatisfy { $0.count == 0 })
    }

    @Test("weekday distribution computes per-weekday due/completed counts across a habit's history")
    func weekdayDistributionComputesCounts() throws {
        let start = try date(2026, 7, 13) // Monday
        let referenceDate = try date(2026, 7, 22) // Wednesday, 10 days later
        let (habit, occurrence) = makeDailyHabit(createdAt: start)
        let insightsService = try makeInsightsService()

        complete(occurrence, habit: habit, on: try date(2026, 7, 13)) // Mon (1/2)
        complete(occurrence, habit: habit, on: try date(2026, 7, 20)) // Mon (2/2)
        complete(occurrence, habit: habit, on: try date(2026, 7, 14)) // Tue (1/2)
        complete(occurrence, habit: habit, on: try date(2026, 7, 16)) // Thu (1/1)

        let slices = insightsService.weekdayDistribution(for: habit, referenceDate: referenceDate)

        let monday = try #require(slices.first { $0.weekday == .monday })
        let tuesday = try #require(slices.first { $0.weekday == .tuesday })
        let wednesday = try #require(slices.first { $0.weekday == .wednesday })
        let thursday = try #require(slices.first { $0.weekday == .thursday })
        let friday = try #require(slices.first { $0.weekday == .friday })

        #expect(monday.dueCount == 2 && monday.completedCount == 2)
        #expect(tuesday.dueCount == 2 && tuesday.completedCount == 1)
        #expect(abs(tuesday.rate - 0.5) < 0.0001)
        #expect(wednesday.dueCount == 2 && wednesday.completedCount == 0)
        #expect(thursday.dueCount == 1 && thursday.completedCount == 1)
        #expect(friday.dueCount == 1 && friday.completedCount == 0)
    }

    @Test("weekday distribution reports zero due count for non-due weekdays on a Weekdays-only habit")
    func weekdayDistributionExcludesNonDueWeekdaysForWeekdaysHabit() throws {
        let friday = try date(2026, 7, 17)
        let referenceDate = try date(2026, 7, 20) // the following Monday
        let habit = Habit(
            name: "Work", icon: "briefcase.fill", accentColor: .sky,
            frequency: .weekdays([.monday, .tuesday, .wednesday, .thursday, .friday]),
            createdAt: friday, displayOrder: 0
        )
        let occurrence = Occurrence(title: "Work", displayOrder: 0, scheduleProvider: .unscheduled)
        habit.occurrences = [occurrence]
        let insightsService = try makeInsightsService()

        let slices = insightsService.weekdayDistribution(for: habit, referenceDate: referenceDate)
        let saturday = try #require(slices.first { $0.weekday == .saturday })
        let sunday = try #require(slices.first { $0.weekday == .sunday })

        #expect(saturday.dueCount == 0)
        #expect(saturday.rate == 0)
        #expect(sunday.dueCount == 0)
    }

    @Test("weekday distribution treats every day as due for a weekly-target habit")
    func weekdayDistributionAllDaysDueForWeeklyTargetHabit() throws {
        let start = try date(2026, 7, 13) // Monday
        let referenceDate = try date(2026, 7, 19) // Sunday, one full week later
        let habit = Habit(
            name: "Gym", icon: "dumbbell.fill", accentColor: .coral,
            frequency: .timesPerWeek(target: 3),
            createdAt: start, displayOrder: 0
        )
        let occurrence = Occurrence(title: "Gym", displayOrder: 0, scheduleProvider: .unscheduled)
        habit.occurrences = [occurrence]
        let insightsService = try makeInsightsService()

        let slices = insightsService.weekdayDistribution(for: habit, referenceDate: referenceDate)

        #expect(slices.allSatisfy { $0.dueCount == 1 })
    }
}
