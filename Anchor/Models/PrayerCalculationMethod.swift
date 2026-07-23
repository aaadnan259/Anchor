import Foundation

/// Mirrors Adhan's CalculationMethod without leaking the Adhan type outside PrayerService.
enum PrayerCalculationMethod: String, CaseIterable, Identifiable, Codable {
    case muslimWorldLeague, egyptian, karachi, ummAlQura, dubai, moonsightingCommittee
    case northAmerica, kuwait, qatar, singapore, tehran, turkey, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .muslimWorldLeague: "Muslim World League"
        case .egyptian: "Egyptian"
        case .karachi: "Karachi"
        case .ummAlQura: "Umm al-Qura"
        case .dubai: "Dubai"
        case .moonsightingCommittee: "Moonsighting Committee"
        case .northAmerica: "ISNA"
        case .kuwait: "Kuwait"
        case .qatar: "Qatar"
        case .singapore: "Singapore"
        case .tehran: "Tehran"
        case .turkey: "Diyanet"
        case .other: "Other"
        }
    }
}
