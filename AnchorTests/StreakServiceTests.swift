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

    /// Wires a Completion directly into the in-memory relationship graph, bypassing
    /// CompletionService/ModelContext entirely — StreakService only ever reads this array.
    private func complete(_ occurrence: Occurrence, habit: Habit, on day: Date) {
        let completion = Completion(habit: habit, occurrence: occurrence, day: calendar.startOfDay(for: day))
        occurrence.completions.append(completion)
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
}
