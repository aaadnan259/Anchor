import Foundation
import SwiftData

@MainActor
struct CompletionService {
    let context: ModelContext
    private let calendar: Calendar = .current

    func isCompleted(occurrence: Occurrence, on day: Date) -> Bool {
        let normalized = calendar.startOfDay(for: day)
        return occurrence.completions.contains { calendar.isDate($0.day, inSameDayAs: normalized) }
    }

    func isFullyCompleted(habit: Habit, on day: Date) -> Bool {
        guard !habit.occurrences.isEmpty else { return false }
        return habit.occurrences.allSatisfy { isCompleted(occurrence: $0, on: day) }
    }

    /// Distinct days within `interval` on which `habit` has at least one recorded completion.
    func completedDayCount(habit: Habit, in interval: DateInterval) -> Int {
        let allCompletions = habit.occurrences.flatMap(\.completions)
        let uniqueDays = Set(
            allCompletions
                .filter { interval.contains($0.day) }
                .map { calendar.startOfDay(for: $0.day) }
        )
        return uniqueDays.count
    }

    func toggle(habit: Habit, occurrence: Occurrence, on day: Date) {
        let normalized = calendar.startOfDay(for: day)
        if let existing = occurrence.completions.first(where: { calendar.isDate($0.day, inSameDayAs: normalized) }) {
            context.delete(existing)
        } else {
            context.insert(Completion(habit: habit, occurrence: occurrence, day: normalized))
        }
        try? context.save()
    }

    func isShielded(habit: Habit, on day: Date) -> Bool {
        let normalized = calendar.startOfDay(for: day)
        return habit.shields.contains { calendar.isDate($0.day, inSameDayAs: normalized) }
    }

    func toggleShield(habit: Habit, on day: Date) {
        let normalized = calendar.startOfDay(for: day)
        if let existing = habit.shields.first(where: { calendar.isDate($0.day, inSameDayAs: normalized) }) {
            context.delete(existing)
        } else {
            context.insert(Shield(habit: habit, day: normalized))
        }
        try? context.save()
    }
}
