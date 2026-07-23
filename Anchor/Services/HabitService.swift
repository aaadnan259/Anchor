import Foundation
import SwiftData

@MainActor
struct HabitService {
    let context: ModelContext

    func fetchAll() -> [Habit] {
        (try? context.fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.displayOrder)]))) ?? []
    }

    func create(
        name: String,
        icon: String,
        accentColor: AccentColor,
        frequency: Frequency,
        occurrences: [(title: String, scheduleProvider: ScheduleProviderKind)],
        reminderEnabled: Bool,
        displayOrder: Int
    ) -> Habit {
        let habit = Habit(
            name: name,
            icon: icon,
            accentColor: accentColor,
            frequency: frequency,
            reminderEnabled: reminderEnabled,
            displayOrder: displayOrder
        )
        habit.occurrences = occurrences.enumerated().map { index, item in
            Occurrence(title: item.title, displayOrder: index, scheduleProvider: item.scheduleProvider)
        }
        context.insert(habit)
        try? context.save()
        return habit
    }

    func update(
        _ habit: Habit,
        name: String,
        icon: String,
        accentColor: AccentColor,
        frequency: Frequency,
        reminderEnabled: Bool
    ) {
        habit.name = name
        habit.icon = icon
        habit.accentColor = accentColor
        habit.frequency = frequency
        habit.reminderEnabled = reminderEnabled
        try? context.save()
    }

    func updateOccurrence(_ occurrence: Occurrence, scheduleProvider: ScheduleProviderKind) {
        occurrence.scheduleProvider = scheduleProvider
        try? context.save()
    }

    func archive(_ habit: Habit) {
        habit.archived = true
        try? context.save()
    }

    func unarchive(_ habit: Habit) {
        habit.archived = false
        try? context.save()
    }

    func delete(_ habit: Habit) {
        context.delete(habit)
        try? context.save()
    }

    func reorder(_ habits: [Habit]) {
        for (index, habit) in habits.enumerated() {
            habit.displayOrder = index
        }
        try? context.save()
    }

    func seedStarterHabitsIfNeeded(existingHabits: [Habit]) {
        guard existingHabits.isEmpty else { return }

        _ = create(
            name: "Prayer",
            icon: "moon.stars.fill",
            accentColor: .violet,
            frequency: .daily,
            occurrences: [
                ("Fajr", .prayer(.fajr)),
                ("Dhuhr", .prayer(.dhuhr)),
                ("Asr", .prayer(.asr)),
                ("Maghrib", .prayer(.maghrib)),
                ("Isha", .prayer(.isha))
            ],
            reminderEnabled: true,
            displayOrder: 0
        )

        _ = create(
            name: "Gym",
            icon: "dumbbell.fill",
            accentColor: .coral,
            frequency: .timesPerWeek(target: 5),
            occurrences: [("Gym", .unscheduled)],
            reminderEnabled: false,
            displayOrder: 1
        )

        _ = create(
            name: "Work",
            icon: "briefcase.fill",
            accentColor: .sky,
            frequency: .weekdays([.monday, .tuesday, .wednesday, .thursday, .friday]),
            occurrences: [("Work", .unscheduled)],
            reminderEnabled: false,
            displayOrder: 2
        )
    }
}
