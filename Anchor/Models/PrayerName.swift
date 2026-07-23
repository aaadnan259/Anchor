import Foundation

enum PrayerName: String, Codable, CaseIterable, Identifiable, Sendable {
    case fajr, dhuhr, asr, maghrib, isha

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fajr: "Fajr"
        case .dhuhr: "Dhuhr"
        case .asr: "Asr"
        case .maghrib: "Maghrib"
        case .isha: "Isha"
        }
    }
}
