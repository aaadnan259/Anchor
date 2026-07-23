import Foundation

enum Frequency: Codable, Equatable, Sendable {
    case daily
    case weekdays([Weekday])
    case timesPerWeek(target: Int)

    var displayName: String {
        switch self {
        case .daily:
            return "Every day"
        case .weekdays(let days):
            let daySet = Set(days)
            let weekdaySet: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
            if daySet == weekdaySet {
                return "Weekdays"
            }
            return days.sorted().map(\.shortLabel).joined(separator: ", ")
        case .timesPerWeek(let target):
            return "\(target)x per week"
        }
    }
}
