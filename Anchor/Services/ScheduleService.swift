import Foundation
import CoreLocation

@MainActor
struct ScheduleService {
    let prayerService: PrayerService
    let locationService: LocationService

    func todaysOccurrences(for habit: Habit, on date: Date = .now, calendar: Calendar = .current) -> [DueOccurrence] {
        let coordinate = locationService.lastKnownCoordinate
        return habit.occurrences
            .compactMap { occurrence in
                provider(for: occurrence.scheduleProvider, coordinate: coordinate)
                    .schedule(habit: habit, occurrence: occurrence, on: date, calendar: calendar)
            }
            .sorted { $0.occurrence.displayOrder < $1.occurrence.displayOrder }
    }

    func isDue(habit: Habit, on date: Date = .now, calendar: Calendar = .current) -> Bool {
        DueDateRule.isDue(frequency: habit.frequency, on: date, calendar: calendar)
    }

    private func provider(for kind: ScheduleProviderKind, coordinate: CLLocationCoordinate2D?) -> ScheduleProvider {
        switch kind {
        case .unscheduled: WeeklyProvider()
        case .fixedTime: FixedTimeProvider()
        case .prayer: PrayerProvider(prayerService: prayerService, coordinate: coordinate)
        }
    }
}
