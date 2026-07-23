import Foundation

enum Weekday: Int, Codable, CaseIterable, Identifiable, Comparable, Sendable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool { lhs.rawValue < rhs.rawValue }

    var shortLabel: String {
        switch self {
        case .sunday: "Sun"
        case .monday: "Mon"
        case .tuesday: "Tue"
        case .wednesday: "Wed"
        case .thursday: "Thu"
        case .friday: "Fri"
        case .saturday: "Sat"
        }
    }

    static func from(date: Date, calendar: Calendar = .current) -> Weekday {
        let component = calendar.component(.weekday, from: date)
        return Weekday(rawValue: component) ?? .sunday
    }
}
