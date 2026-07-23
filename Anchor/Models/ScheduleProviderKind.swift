import Foundation

enum ScheduleProviderKind: Codable, Equatable, Sendable {
    case unscheduled
    case fixedTime(hour: Int, minute: Int)
    case prayer(PrayerName)
}
