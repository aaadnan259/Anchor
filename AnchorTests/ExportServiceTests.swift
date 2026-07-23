import Foundation
import Testing
@testable import Anchor

@Suite("ExportService")
struct ExportServiceTests {
    // ExportService does no calendar-relative reasoning of its own — it only formats
    // raw Date values via ISO8601DateFormatter (always UTC output), so fixtures use
    // TestSupport's fixed UTC calendar (matching the schedule-related suites) rather
    // than Calendar.current, keeping the exact-string assertions below deterministic
    // regardless of the machine's local timezone.
    private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try TestSupport.date(year, month, day)
    }

    private func dateTime(_ year: Int, _ month: Int, _ day: Int, hour: Int) throws -> Date {
        try #require(TestSupport.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)))
    }

    private func makeHabit(name: String, archived: Bool = false) -> (Habit, Occurrence) {
        let habit = Habit(name: name, icon: "star.fill", accentColor: .indigo, frequency: .daily, archived: archived, displayOrder: 0)
        let occurrence = Occurrence(title: name, displayOrder: 0, scheduleProvider: .unscheduled)
        habit.occurrences = [occurrence]
        return (habit, occurrence)
    }

    @Test("csv produces the header and one correctly comma-joined row per completion")
    func csvProducesExpectedRows() throws {
        let day = try date(2026, 7, 20)
        let completedAt = try dateTime(2026, 7, 20, hour: 6)
        let (habit, occurrence) = makeHabit(name: "Prayer")
        occurrence.completions = [Completion(habit: habit, occurrence: occurrence, day: day, completedAt: completedAt)]

        let csv = ExportService().csv(habits: [habit])
        let lines = csv.components(separatedBy: "\n")

        #expect(lines.count == 2)
        #expect(lines[0] == "Habit,Occurrence,Day,Completed At")
        #expect(lines[1] == "Prayer,Prayer,2026-07-20,2026-07-20T06:00:00Z")
    }

    @Test("csv quotes and escapes a habit name containing a comma")
    func csvEscapesCommaInName() throws {
        let day = try date(2026, 7, 20)
        let (habit, occurrence) = makeHabit(name: "Reading, Writing")
        occurrence.completions = [Completion(habit: habit, occurrence: occurrence, day: day, completedAt: day)]

        let csv = ExportService().csv(habits: [habit])
        let lines = csv.components(separatedBy: "\n")

        #expect(lines[1].hasPrefix("\"Reading, Writing\","))
    }

    @Test("csv escapes a habit name containing a double quote")
    func csvEscapesQuoteInName() throws {
        let day = try date(2026, 7, 20)
        let (habit, occurrence) = makeHabit(name: "My \"Big\" Goal")
        occurrence.completions = [Completion(habit: habit, occurrence: occurrence, day: day, completedAt: day)]

        let csv = ExportService().csv(habits: [habit])
        let lines = csv.components(separatedBy: "\n")

        #expect(lines[1].hasPrefix("\"My \"\"Big\"\" Goal\","))
    }

    @Test("csv emits no phantom row for a habit with zero completions")
    func csvHandlesZeroCompletions() throws {
        let (habit, _) = makeHabit(name: "Empty")

        let csv = ExportService().csv(habits: [habit])
        let lines = csv.components(separatedBy: "\n")

        #expect(lines.count == 1)
        #expect(lines[0] == "Habit,Occurrence,Day,Completed At")
    }

    @Test("json round-trips through JSONDecoder with correct field values")
    func jsonRoundTrips() throws {
        let day = try date(2026, 7, 20)
        let completedAt = try dateTime(2026, 7, 20, hour: 6)
        let (habit, occurrence) = makeHabit(name: "Prayer")
        occurrence.completions = [Completion(habit: habit, occurrence: occurrence, day: day, completedAt: completedAt)]

        let data = ExportService().json(habits: [habit])
        let decoded = try JSONDecoder().decode([ExportedHabit].self, from: data)

        #expect(decoded.count == 1)
        #expect(decoded[0].name == "Prayer")
        #expect(decoded[0].frequency == "Every day")
        #expect(decoded[0].archived == false)
        #expect(decoded[0].completions.count == 1)
        #expect(decoded[0].completions[0].occurrence == "Prayer")
        #expect(decoded[0].completions[0].day == "2026-07-20")
        #expect(decoded[0].completions[0].completedAt == "2026-07-20T06:00:00Z")
    }

    @Test("json includes archived habits")
    func jsonIncludesArchivedHabits() throws {
        let (habit, _) = makeHabit(name: "Old Habit", archived: true)

        let data = ExportService().json(habits: [habit])
        let decoded = try JSONDecoder().decode([ExportedHabit].self, from: data)

        #expect(decoded.count == 1)
        #expect(decoded[0].archived == true)
    }
}
