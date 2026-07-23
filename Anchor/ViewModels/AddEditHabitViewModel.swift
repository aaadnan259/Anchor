import Foundation

@Observable
@MainActor
final class AddEditHabitViewModel {
    enum FrequencyKind: String, CaseIterable, Identifiable {
        case daily, weekdays, timesPerWeek

        var id: String { rawValue }

        var label: String {
            switch self {
            case .daily: "Daily"
            case .weekdays: "Weekdays"
            case .timesPerWeek: "Weekly Goal"
            }
        }
    }

    enum OccurrenceMode: Equatable {
        case single
        case prayer
    }

    var name: String = ""
    var icon: String = "star.fill"
    var accentColor: AccentColor = .indigo
    var frequencyKind: FrequencyKind = .daily
    var selectedWeekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    var timesPerWeekTarget: Int = 3
    var reminderEnabled: Bool = false
    var reminderTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
    var occurrenceMode: OccurrenceMode = .single

    private let habitService: HabitService
    private let existingHabit: Habit?
    private let nextDisplayOrder: Int
    private let notificationService: NotificationService
    private let scheduleService: ScheduleService
    private let locationService: LocationService

    var isEditing: Bool { existingHabit != nil }
    var isSaveDisabled: Bool { name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    init(
        habitService: HabitService,
        habit: Habit?,
        nextDisplayOrder: Int,
        notificationService: NotificationService,
        scheduleService: ScheduleService,
        locationService: LocationService
    ) {
        self.habitService = habitService
        self.existingHabit = habit
        self.nextDisplayOrder = nextDisplayOrder
        self.notificationService = notificationService
        self.scheduleService = scheduleService
        self.locationService = locationService
        if let habit {
            load(from: habit)
        }
    }

    func applyPreset(_ preset: HabitPreset) {
        name = preset.name
        icon = preset.icon
        accentColor = preset.accentColor
        reminderEnabled = preset.reminderEnabled
        occurrenceMode = preset.occurrenceMode
        applyFrequency(preset.frequency)
    }

    func applyCustom() {
        name = ""
        icon = "star.fill"
        accentColor = .indigo
        frequencyKind = .daily
        selectedWeekdays = [.monday, .tuesday, .wednesday, .thursday, .friday]
        timesPerWeekTarget = 3
        reminderEnabled = false
        occurrenceMode = .single
    }

    func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        if let existingHabit {
            habitService.update(
                existingHabit,
                name: trimmedName,
                icon: icon,
                accentColor: accentColor,
                frequency: frequency,
                reminderEnabled: reminderEnabled
            )
            if occurrenceMode == .single, let occurrence = existingHabit.occurrences.first {
                habitService.updateOccurrence(occurrence, scheduleProvider: singleOccurrenceSchedule)
            }
        } else {
            _ = habitService.create(
                name: trimmedName,
                icon: icon,
                accentColor: accentColor,
                frequency: frequency,
                occurrences: occurrences(habitName: trimmedName),
                reminderEnabled: reminderEnabled,
                displayOrder: nextDisplayOrder
            )
        }

        let habits = habitService.fetchAll()
        let wantsReminders = reminderEnabled
        let wantsPrayerTimes = occurrenceMode == .prayer
        Task {
            if wantsReminders {
                await notificationService.requestAuthorizationIfNeeded()
            }
            if wantsPrayerTimes {
                locationService.requestAuthorizationIfNeeded()
            }
            await notificationService.rescheduleAll(for: habits, scheduleService: scheduleService)
        }
    }

    private func load(from habit: Habit) {
        name = habit.name
        icon = habit.icon
        accentColor = habit.accentColor
        reminderEnabled = habit.reminderEnabled
        applyFrequency(habit.frequency)

        if habit.occurrences.count > 1 {
            occurrenceMode = .prayer
        } else {
            occurrenceMode = .single
            if let occurrence = habit.occurrences.first, case .fixedTime(let hour, let minute) = occurrence.scheduleProvider {
                reminderTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
            }
        }
    }

    private func applyFrequency(_ frequency: Frequency) {
        switch frequency {
        case .daily:
            frequencyKind = .daily
        case .weekdays(let days):
            frequencyKind = .weekdays
            selectedWeekdays = Set(days)
        case .timesPerWeek(let target):
            frequencyKind = .timesPerWeek
            timesPerWeekTarget = target
        }
    }

    private var frequency: Frequency {
        switch frequencyKind {
        case .daily: .daily
        case .weekdays: .weekdays(selectedWeekdays.sorted())
        case .timesPerWeek: .timesPerWeek(target: timesPerWeekTarget)
        }
    }

    private var singleOccurrenceSchedule: ScheduleProviderKind {
        guard reminderEnabled else { return .unscheduled }
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        return .fixedTime(hour: components.hour ?? 9, minute: components.minute ?? 0)
    }

    private func occurrences(habitName: String) -> [(title: String, scheduleProvider: ScheduleProviderKind)] {
        switch occurrenceMode {
        case .prayer:
            [
                ("Fajr", .prayer(.fajr)),
                ("Dhuhr", .prayer(.dhuhr)),
                ("Asr", .prayer(.asr)),
                ("Maghrib", .prayer(.maghrib)),
                ("Isha", .prayer(.isha))
            ]
        case .single:
            [(habitName, singleOccurrenceSchedule)]
        }
    }
}
