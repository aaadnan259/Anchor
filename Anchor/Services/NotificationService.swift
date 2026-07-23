import Foundation
@preconcurrency import UserNotifications

enum NotificationAuthorization {
    case notDetermined
    case authorized
    case denied
}

@MainActor
struct NotificationService {
    private let center = UNUserNotificationCenter.current()
    private let identifierPrefix = "anchor."
    private let smartReminderPrefix = "anchor.smart."
    private let smartReminderHour = 20

    func requestAuthorizationIfNeeded() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func authorizationStatus() async -> NotificationAuthorization {
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral: .authorized
        case .denied: .denied
        case .notDetermined: .notDetermined
        @unknown default: .notDetermined
        }
    }

    func rescheduleAll(for habits: [Habit], scheduleService: ScheduleService, completionService: CompletionService, smartRemindersEnabled: Bool, calendar: Calendar = .current, daysAhead: Int = 7) async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        let pending = await center.pendingNotificationRequests()
        let ourIdentifiers = pending.map(\.identifier).filter { $0.hasPrefix(identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ourIdentifiers)

        let now = Date.now
        for habit in habits where habit.reminderEnabled && !habit.archived {
            for dayOffset in 0..<daysAhead {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
                let due = scheduleService.todaysOccurrences(for: habit, on: date, calendar: calendar)
                for occurrence in due {
                    guard let time = occurrence.time, time > now else { continue }
                    schedule(habitID: habit.id, occurrence: occurrence.occurrence, habitName: habit.name, at: time, calendar: calendar)
                }
            }
        }

        if smartRemindersEnabled {
            scheduleSmartReminders(for: habits, completionService: completionService, calendar: calendar, now: now)
        }
    }

    private func scheduleSmartReminders(for habits: [Habit], completionService: CompletionService, calendar: Calendar, now: Date) {
        guard let checkInTime = calendar.date(bySettingHour: smartReminderHour, minute: 0, second: 0, of: now), checkInTime > now else { return }
        for habit in habits where !habit.archived {
            guard DueDateRule.isDue(frequency: habit.frequency, on: now, calendar: calendar) else { continue }
            guard !completionService.isFullyCompleted(habit: habit, on: now) else { continue }

            let content = UNMutableNotificationContent()
            content.title = habit.name
            content.body = "You haven't completed this yet today."
            content.sound = .default

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: checkInTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = "\(smartReminderPrefix)\(habit.id.uuidString).\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request)
        }
    }

    private func schedule(habitID: UUID, occurrence: Occurrence, habitName: String, at date: Date, calendar: Calendar) {
        let content = UNMutableNotificationContent()
        content.title = habitName
        content.body = occurrence.title
        content.sound = .default

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = "\(identifierPrefix)\(habitID.uuidString).\(occurrence.id.uuidString).\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }
}
