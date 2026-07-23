import Foundation

/// Mirrors Adhan's Madhab (determines Asr calculation) without leaking the Adhan type outside PrayerService.
enum PrayerMadhab: String, CaseIterable, Identifiable, Codable {
    case shafi, hanafi

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .shafi: "Shafi"
        case .hanafi: "Hanafi"
        }
    }
}
