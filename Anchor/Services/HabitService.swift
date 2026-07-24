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
        displayOrder: Int,
        targetValue: Int? = nil,
        unit: String? = nil
    ) -> Habit {
        let habit = Habit(
            name: name,
            icon: icon,
            accentColor: accentColor,
            frequency: frequency,
            reminderEnabled: reminderEnabled,
            displayOrder: displayOrder,
            targetValue: targetValue,
            unit: unit
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
        reminderEnabled: Bool,
        targetValue: Int?,
        unit: String?
    ) {
        habit.name = name
        habit.icon = icon
        habit.accentColor = accentColor
        habit.frequency = frequency
        habit.reminderEnabled = reminderEnabled
        habit.targetValue = targetValue
        habit.unit = unit
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

    func create(from preset: HabitPreset, displayOrder: Int) -> Habit {
        create(
            name: preset.name,
            icon: preset.icon,
            accentColor: preset.accentColor,
            frequency: preset.frequency,
            occurrences: occurrences(for: preset),
            reminderEnabled: preset.reminderEnabled,
            displayOrder: displayOrder
        )
    }

    @discardableResult
    func duplicate(_ habit: Habit) -> Habit {
        create(
            name: "\(habit.name) Copy",
            icon: habit.icon,
            accentColor: habit.accentColor,
            frequency: habit.frequency,
            occurrences: habit.occurrences
                .sorted { $0.displayOrder < $1.displayOrder }
                .map { ($0.title, $0.scheduleProvider) },
            reminderEnabled: habit.reminderEnabled,
            displayOrder: fetchAll().count,
            targetValue: habit.targetValue,
            unit: habit.unit
        )
    }

    private func occurrences(for preset: HabitPreset) -> [(title: String, scheduleProvider: ScheduleProviderKind)] {
        switch preset.occurrenceMode {
        case .prayer:
            [
                ("Fajr", .prayer(.fajr)),
                ("Dhuhr", .prayer(.dhuhr)),
                ("Asr", .prayer(.asr)),
                ("Maghrib", .prayer(.maghrib)),
                ("Isha", .prayer(.isha))
            ]
        case .single:
            [(preset.name, .unscheduled)]
        }
    }
}
