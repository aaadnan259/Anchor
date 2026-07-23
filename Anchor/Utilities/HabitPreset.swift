import Foundation

struct HabitPreset: Identifiable {
    let id = UUID()
    let title: String
    let name: String
    let icon: String
    let accentColor: AccentColor
    let frequency: Frequency
    let reminderEnabled: Bool
    let occurrenceMode: AddEditHabitViewModel.OccurrenceMode

    static let all: [HabitPreset] = [
        HabitPreset(
            title: "Prayer",
            name: "Prayer",
            icon: "moon.stars.fill",
            accentColor: .violet,
            frequency: .daily,
            reminderEnabled: true,
            occurrenceMode: .prayer
        ),
        HabitPreset(
            title: "Gym",
            name: "Gym",
            icon: "dumbbell.fill",
            accentColor: .coral,
            frequency: .timesPerWeek(target: 5),
            reminderEnabled: false,
            occurrenceMode: .single
        ),
        HabitPreset(
            title: "Work",
            name: "Work",
            icon: "briefcase.fill",
            accentColor: .sky,
            frequency: .weekdays([.monday, .tuesday, .wednesday, .thursday, .friday]),
            reminderEnabled: false,
            occurrenceMode: .single
        )
    ]
}
