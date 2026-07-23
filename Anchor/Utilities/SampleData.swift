import SwiftData

@MainActor
enum SampleData {
    static var previewContainer: ModelContainer = {
        let schema = Schema([Habit.self, Occurrence.self, Completion.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        guard let container = try? ModelContainer(for: schema, configurations: [configuration]) else {
            preconditionFailure("Failed to create in-memory preview container")
        }
        seed(into: container.mainContext)
        return container
    }()

    static func seed(into context: ModelContext) {
        let prayer = Habit(
            name: "Prayer",
            icon: "moon.stars.fill",
            accentColor: .violet,
            frequency: .daily,
            reminderEnabled: true,
            displayOrder: 0
        )
        prayer.occurrences = [
            ("Fajr", PrayerName.fajr),
            ("Dhuhr", PrayerName.dhuhr),
            ("Asr", PrayerName.asr),
            ("Maghrib", PrayerName.maghrib),
            ("Isha", PrayerName.isha)
        ].enumerated().map { index, item in
            Occurrence(title: item.0, displayOrder: index, scheduleProvider: .prayer(item.1))
        }

        let gym = Habit(
            name: "Gym",
            icon: "dumbbell.fill",
            accentColor: .coral,
            frequency: .timesPerWeek(target: 5),
            displayOrder: 1
        )
        gym.occurrences = [Occurrence(title: "Gym", displayOrder: 0)]

        let work = Habit(
            name: "Work",
            icon: "briefcase.fill",
            accentColor: .sky,
            frequency: .weekdays([.monday, .tuesday, .wednesday, .thursday, .friday]),
            displayOrder: 2
        )
        work.occurrences = [Occurrence(title: "Work", displayOrder: 0)]

        for habit in [prayer, gym, work] {
            context.insert(habit)
        }

        try? context.save()
    }
}
