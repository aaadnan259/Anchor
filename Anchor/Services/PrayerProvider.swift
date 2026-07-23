import Foundation
import CoreLocation

struct PrayerProvider: ScheduleProvider {
    let prayerService: PrayerService
    let coordinate: CLLocationCoordinate2D?

    func schedule(habit: Habit, occurrence: Occurrence, on date: Date, calendar: Calendar) -> DueOccurrence? {
        guard case .prayer(let name) = occurrence.scheduleProvider else { return nil }
        guard isDue(habit: habit, on: date, calendar: calendar) else { return nil }
        let time = coordinate.flatMap { prayerService.time(for: name, coordinate: $0, on: date, calendar: calendar) }
        return DueOccurrence(occurrence: occurrence, time: time)
    }
}
