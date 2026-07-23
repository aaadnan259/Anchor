import Foundation

enum Frequency: Codable, Equatable, Sendable {
    case daily
    case weekdays([Weekday])
    case timesPerWeek(target: Int)
}
