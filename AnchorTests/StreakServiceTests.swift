import Foundation
import SwiftData
import Testing
@testable import Anchor

@MainActor
@Suite("StreakService")
struct StreakServiceTests {
    // CompletionService/StreakService use Calendar.current internally (correct for real
    // users' local day boundaries), so fixtures here are built with the same calendar
    // rather than TestSupport's injected UTC calendar used by the schedule-related tests.
    private let calendar = Calendar.current

    private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }

    private func makeDailyHabit(createdAt: Date) -> (Habit, Occurrence) {
        let habit = Habit(name: "Prayer", icon: "moon.stars.fill", accentColor: .violet, frequency: .daily, createdAt: createdAt, displayOrder: 0)
        let occurrence = Occurrence(title: "Prayer", displayOrder: 0, scheduleProvider: .unscheduled)
        habit.occurrences = [occurrence]
        return (habit, occurrence)
    }

    private func makeQuantifiableHabit(target: Int, createdAt: Date) -> (Habit, Occurrence) {
        let habit = Habit(
            name: "Water", icon: "drop.fill", accentColor: .sky, frequency: .daily,
            createdAt: createdAt, displayOrder: 0, targetValue: target, unit: "glasses"
        )
        let occurrence = Occurrence(title: "Water", displayOrder: 0, scheduleProvider: .unscheduled)
        habit.occurrences = [occurrence]
        return (habit, occurrence)
    }

    private func makeDailyHabitWithTwoOccurrences(createdAt: Date) -> (Habit, Occurrence, Occurrence) {
        let habit = Habit(name: "Prayer", icon: "moon.stars.fill", accentColor: .violet, frequency: .daily, createdAt: createdAt, displayOrder: 0)
        let first = Occurrence(title: "Fajr", displayOrder: 0, scheduleProvider: .unscheduled)
        let second = Occurrence(title: "Dhuhr", displayOrder: 1, scheduleProvider: .unscheduled)
        habit.occurrences = [first, second]
        return (habit, first, second)
    }

    /// Wires a Completion directly into the in-memory relationship graph, bypassing
    /// CompletionService/ModelContext entirely — StreakService only ever reads this array.
    private func complete(_ occurrence: Occurrence, habit: Habit, on day: Date, value: Int = 1) {
        let completion = Completion(habit: habit, occurrence: occurrence, day: calendar.startOfDay(for: day), value: value)
        occurrence.completions.append(completion)
    }

    /// Wires a Shield directly into the in-memory relationship graph, bypassing
    /// CompletionService/ModelContext entirely — StreakService only ever reads this array.
    private func shield(_ habit: Habit, on day: Date) {
        let shield = Shield(habit: habit, day: calendar.startOfDay(for: day))
        habit.shields.append(shield)
    }

    @Test("current streak is zero with no completions")
    func zeroWithNoCompletions() throws {
        let today = try date(2026, 7, 22)
        let (habit, _) = makeDailyHabit(createdAt: today)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        #expect(streakService.currentStreak(for: habit, referenceDate: today) == 0)
    }

    @Test("today in progress does not break an existing streak")
    func todayInProgressDoesNotBreakStreak() throws {
        let today = try date(2026, 7, 22)
        let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: today))
        let (habit, occurrence) = makeDailyHabit(createdAt: yesterday)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        complete(occurrence, habit: habit, on: yesterday)

        #expect(streakService.currentStreak(for: habit, referenceDate: today) == 1)
    }

    @Test("missing a due day breaks the streak")
    func missedDueDayBreaksStreak() throws {
        let today = try date(2026, 7, 22)
        let twoDaysAgo = try #require(calendar.date(byAdding: .day, value: -2, to: today))
        let (habit, occurrence) = makeDailyHabit(createdAt: twoDaysAgo)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        complete(occurrence, habit: habit, on: twoDaysAgo)
        // Yesterday and today are left incomplete.

        #expect(streakService.currentStreak(for: habit, referenceDate: today) == 0)
    }

    @Test("consecutive completed days build a streak")
    func consecutiveDaysBuildStreak() throws {
        let today = try date(2026, 7, 22)
        let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: today))
        let (habit, occurrence) = makeDailyHabit(createdAt: yesterday)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        complete(occurrence, habit: habit, on: yesterday)
        complete(occurrence, habit: habit, on: today)

        #expect(streakService.currentStreak(for: habit, referenceDate: today) == 2)
    }

    @Test("non-due weekdays do not break a weekday habit's streak")
    func nonDueWeekdaysDoNotBreakStreak() throws {
        // Friday July 17 and Monday July 20, 2026 — Sat/Sun between them are not due.
        let friday = try date(2026, 7, 17)
        let monday = try date(2026, 7, 20)
        let habit = Habit(
            name: "Work",
            icon: "briefcase.fill",
            accentColor: .sky,
            frequency: .weekdays([.monday, .tuesday, .wednesday, .thursday, .friday]),
            createdAt: friday,
            displayOrder: 0
        )
        let occurrence = Occurrence(title: "Work", displayOrder: 0, scheduleProvider: .unscheduled)
        habit.occurrences = [occurrence]
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        complete(occurrence, habit: habit, on: friday)
        complete(occurrence, habit: habit, on: monday)

        #expect(streakService.currentStreak(for: habit, referenceDate: monday) == 2)
    }

    @Test("best streak finds the longest run in history, not just the most recent")
    func bestStreakFindsLongestRun() throws {
        let start = try date(2026, 7, 10)
        let (habit, occurrence) = makeDailyHabit(createdAt: start)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        // A 4-day run (offsets 0-3), a gap at offset 4, then a 2-day run (offsets 5-6).
        for offset in 0...3 {
            let day = try #require(calendar.date(byAdding: .day, value: offset, to: start))
            complete(occurrence, habit: habit, on: day)
        }
        for offset in 5...6 {
            let day = try #require(calendar.date(byAdding: .day, value: offset, to: start))
            complete(occurrence, habit: habit, on: day)
        }

        let referenceDate = try #require(calendar.date(byAdding: .day, value: 6, to: start))
        #expect(streakService.bestStreak(for: habit, referenceDate: referenceDate) == 4)
        #expect(streakService.currentStreak(for: habit, referenceDate: referenceDate) == 2)
    }

    @Test("weekly target habit builds a streak once the target is met each week")
    func weeklyTargetStreak() throws {
        let mondayWeek1 = try date(2026, 7, 6)
        let habit = Habit(
            name: "Gym",
            icon: "dumbbell.fill",
            accentColor: .coral,
            frequency: .timesPerWeek(target: 2),
            createdAt: mondayWeek1,
            displayOrder: 0
        )
        let occurrence = Occurrence(title: "Gym", displayOrder: 0, scheduleProvider: .unscheduled)
        habit.occurrences = [occurrence]
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        let wednesdayWeek1 = try #require(calendar.date(byAdding: .day, value: 2, to: mondayWeek1))
        complete(occurrence, habit: habit, on: mondayWeek1)
        complete(occurrence, habit: habit, on: wednesdayWeek1)

        let mondayWeek2 = try #require(calendar.date(byAdding: .day, value: 7, to: mondayWeek1))
        let wednesdayWeek2 = try #require(calendar.date(byAdding: .day, value: 9, to: mondayWeek1))
        complete(occurrence, habit: habit, on: mondayWeek2)
        complete(occurrence, habit: habit, on: wednesdayWeek2)

        #expect(streakService.currentStreak(for: habit, referenceDate: wednesdayWeek2) == 2)
    }

    @Test("weekly target streak breaks when a week falls short")
    func weeklyTargetStreakBreaksOnShortfall() throws {
        let mondayWeek1 = try date(2026, 7, 6)
        let habit = Habit(
            name: "Gym",
            icon: "dumbbell.fill",
            accentColor: .coral,
            frequency: .timesPerWeek(target: 2),
            createdAt: mondayWeek1,
            displayOrder: 0
        )
        let occurrence = Occurrence(title: "Gym", displayOrder: 0, scheduleProvider: .unscheduled)
        habit.occurrences = [occurrence]
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        // Week 1: only 1 completion, short of the target of 2.
        complete(occurrence, habit: habit, on: mondayWeek1)

        // Week 2: meets target.
        let mondayWeek2 = try #require(calendar.date(byAdding: .day, value: 7, to: mondayWeek1))
        let wednesdayWeek2 = try #require(calendar.date(byAdding: .day, value: 9, to: mondayWeek1))
        complete(occurrence, habit: habit, on: mondayWeek2)
        complete(occurrence, habit: habit, on: wednesdayWeek2)

        #expect(streakService.currentStreak(for: habit, referenceDate: wednesdayWeek2) == 1)
    }

    @Test("daily history reports missed for a due day with zero completions")
    func dailyHistoryReportsMissedWithZeroCompletions() throws {
        let today = try date(2026, 7, 22)
        let (habit, _, _) = makeDailyHabitWithTwoOccurrences(createdAt: today)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        let history = streakService.dailyHistory(for: habit, days: 1, referenceDate: today)

        #expect(history == [.missed])
    }

    @Test("daily history reports partial for a due day with some but not all occurrences completed")
    func dailyHistoryReportsPartialWithSomeCompletions() throws {
        let today = try date(2026, 7, 22)
        let (habit, first, _) = makeDailyHabitWithTwoOccurrences(createdAt: today)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        complete(first, habit: habit, on: today)

        let history = streakService.dailyHistory(for: habit, days: 1, referenceDate: today)

        #expect(history == [.partial])
    }

    @Test("daily history reports completed for a due day with all occurrences completed")
    func dailyHistoryReportsCompletedWithAllCompletions() throws {
        let today = try date(2026, 7, 22)
        let (habit, first, second) = makeDailyHabitWithTwoOccurrences(createdAt: today)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        complete(first, habit: habit, on: today)
        complete(second, habit: habit, on: today)

        let history = streakService.dailyHistory(for: habit, days: 1, referenceDate: today)

        #expect(history == [.completed])
    }

    @Test("daily history reports notDue for a day before the habit was created")
    func dailyHistoryReportsNotDueBeforeHabitCreated() throws {
        let today = try date(2026, 7, 22)
        let (habit, _, _) = makeDailyHabitWithTwoOccurrences(createdAt: today)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        let history = streakService.dailyHistory(for: habit, days: 2, referenceDate: today)

        #expect(history.first == .notDue)
    }

    @Test("a shielded day does not break the current streak")
    func shieldedDayDoesNotBreakStreak() throws {
        let start = try date(2026, 7, 20)
        let (habit, occurrence) = makeDailyHabit(createdAt: start)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        let day2 = try #require(calendar.date(byAdding: .day, value: 1, to: start))
        let day3 = try #require(calendar.date(byAdding: .day, value: 2, to: start))

        complete(occurrence, habit: habit, on: start)
        shield(habit, on: day2)
        complete(occurrence, habit: habit, on: day3)

        #expect(streakService.currentStreak(for: habit, referenceDate: day3) == 2)
    }

    @Test("a shielded day does not itself increment the streak")
    func shieldedDayDoesNotIncrementStreak() throws {
        let today = try date(2026, 7, 22)
        let (habit, _) = makeDailyHabit(createdAt: today)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        shield(habit, on: today)

        #expect(streakService.currentStreak(for: habit, referenceDate: today) == 0)
    }

    @Test("best streak carries forward unchanged across a shielded day")
    func bestStreakCarriesForwardAcrossShieldedDay() throws {
        let start = try date(2026, 7, 20)
        let (habit, occurrence) = makeDailyHabit(createdAt: start)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        let day2 = try #require(calendar.date(byAdding: .day, value: 1, to: start))
        let day3 = try #require(calendar.date(byAdding: .day, value: 2, to: start))

        complete(occurrence, habit: habit, on: start)
        shield(habit, on: day2)
        complete(occurrence, habit: habit, on: day3)

        #expect(streakService.bestStreak(for: habit, referenceDate: day3) == 2)
    }

    @Test("daily history reports shielded for a due, incomplete, shielded day")
    func dailyHistoryReportsShielded() throws {
        let today = try date(2026, 7, 22)
        let (habit, _, _) = makeDailyHabitWithTwoOccurrences(createdAt: today)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        shield(habit, on: today)

        let history = streakService.dailyHistory(for: habit, days: 1, referenceDate: today)

        #expect(history == [.shielded])
    }

    @Test("daily history reports completed, not shielded, for a day that is both fully completed and shielded")
    func dailyHistoryReportsCompletedOverShielded() throws {
        let today = try date(2026, 7, 22)
        let (habit, first, second) = makeDailyHabitWithTwoOccurrences(createdAt: today)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        complete(first, habit: habit, on: today)
        complete(second, habit: habit, on: today)
        shield(habit, on: today)

        let history = streakService.dailyHistory(for: habit, days: 1, referenceDate: today)

        #expect(history == [.completed])
    }

    @Test("a quantifiable occurrence below target on a past due day is not completed and breaks the streak")
    func quantifiableBelowTargetDoesNotComplete() throws {
        let today = try date(2026, 7, 22)
        let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: today))
        let twoDaysAgo = try #require(calendar.date(byAdding: .day, value: -2, to: today))
        let (habit, occurrence) = makeQuantifiableHabit(target: 8, createdAt: twoDaysAgo)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        complete(occurrence, habit: habit, on: twoDaysAgo, value: 8)
        complete(occurrence, habit: habit, on: yesterday, value: 3)
        complete(occurrence, habit: habit, on: today, value: 10)

        // Yesterday's below-target log counts as a missed due day, breaking the chain
        // back to two days ago — only today's own completion carries forward.
        #expect(streakService.currentStreak(for: habit, referenceDate: today) == 1)
    }

    @Test("a quantifiable occurrence at or above target completes normally and builds a streak")
    func quantifiableAtOrAboveTargetCompletes() throws {
        let today = try date(2026, 7, 22)
        let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: today))
        let (habit, occurrence) = makeQuantifiableHabit(target: 8, createdAt: yesterday)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        complete(occurrence, habit: habit, on: yesterday, value: 8)
        complete(occurrence, habit: habit, on: today, value: 10)

        #expect(streakService.currentStreak(for: habit, referenceDate: today) == 2)
    }

    @Test("daily history transitions from partial to completed as a quantifiable day crosses target")
    func dailyHistoryQuantifiablePartialToCompleted() throws {
        let today = try date(2026, 7, 22)
        let (belowHabit, belowOccurrence) = makeQuantifiableHabit(target: 8, createdAt: today)
        let (atTargetHabit, atTargetOccurrence) = makeQuantifiableHabit(target: 8, createdAt: today)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        complete(belowOccurrence, habit: belowHabit, on: today, value: 5)
        complete(atTargetOccurrence, habit: atTargetHabit, on: today, value: 8)

        #expect(streakService.dailyHistory(for: belowHabit, days: 1, referenceDate: today) == [.partial])
        #expect(streakService.dailyHistory(for: atTargetHabit, days: 1, referenceDate: today) == [.completed])
    }

    @Test("daily history reports missed, not partial, for a quantifiable day with nothing logged at all")
    func dailyHistoryQuantifiableNothingLoggedIsMissed() throws {
        let today = try date(2026, 7, 22)
        let (habit, _) = makeQuantifiableHabit(target: 8, createdAt: today)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        let history = streakService.dailyHistory(for: habit, days: 1, referenceDate: today)

        #expect(history == [.missed])
    }

    @Test("day completion state agrees with daily history for every day in a mixed range")
    func dayCompletionStateAgreesWithDailyHistory() throws {
        let start = try date(2026, 7, 17)
        let today = try #require(calendar.date(byAdding: .day, value: 4, to: start))
        let (habit, first, second) = makeDailyHabitWithTwoOccurrences(createdAt: start)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        let day1 = try #require(calendar.date(byAdding: .day, value: 1, to: start))
        let day2 = try #require(calendar.date(byAdding: .day, value: 2, to: start))

        complete(first, habit: habit, on: start)
        complete(second, habit: habit, on: start)
        complete(first, habit: habit, on: day1)
        shield(habit, on: day2)
        // day3 and today (day4) are left with nothing logged.

        let history = streakService.dailyHistory(for: habit, days: 5, referenceDate: today)

        for offset in 0..<5 {
            let day = try #require(calendar.date(byAdding: .day, value: offset, to: start))
            #expect(streakService.dayCompletionState(for: habit, on: day, referenceDate: today) == history[offset])
        }
        #expect(history == [.completed, .partial, .shielded, .missed, .missed])
    }

    @Test("day completion state reports notDue for a date after the reference date")
    func dayCompletionStateNotDueForFutureDate() throws {
        let today = try date(2026, 7, 22)
        let tomorrow = try #require(calendar.date(byAdding: .day, value: 1, to: today))
        let (habit, _) = makeDailyHabit(createdAt: today)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        // Without the future-date guard this would report .missed (daily habits are always "due"),
        // which would render an unlogged future calendar day as already missed before it happens.
        #expect(streakService.dayCompletionState(for: habit, on: tomorrow, referenceDate: today) == .notDue)
    }

    @Test("day completion state reports notDue for a date before the habit was created")
    func dayCompletionStateNotDueBeforeHabitCreated() throws {
        let today = try date(2026, 7, 22)
        let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: today))
        let (habit, _) = makeDailyHabit(createdAt: today)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        #expect(streakService.dayCompletionState(for: habit, on: yesterday, referenceDate: today) == .notDue)
    }

    @Test("day completion state reports missed for today with nothing logged, without today-in-progress leniency")
    func dayCompletionStateTodayNothingLoggedIsMissed() throws {
        let today = try date(2026, 7, 22)
        let (habit, _) = makeDailyHabit(createdAt: today)
        let streakService = StreakService(completionService: CompletionService(context: try TestSupport.makeContext()))

        // currentStreak() treats an in-progress today leniently (doesn't break the streak); dayCompletionState
        // is a per-day rendering lookup and must not inherit that streak-continuity-specific leniency.
        #expect(streakService.dayCompletionState(for: habit, on: today, referenceDate: today) == .missed)
    }
}
