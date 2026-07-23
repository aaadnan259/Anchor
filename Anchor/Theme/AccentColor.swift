import SwiftUI

enum AccentColor: String, CaseIterable, Codable, Identifiable {
    case indigo, teal, coral, amber, emerald, rose, sky, violet

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .indigo: Color(hex: 0x6E6BFF)
        case .teal: Color(hex: 0x2DD4C7)
        case .coral: Color(hex: 0xFF6B6B)
        case .amber: Color(hex: 0xFFB833)
        case .emerald: Color(hex: 0x34E5A8)
        case .rose: Color(hex: 0xFF4D8D)
        case .sky: Color(hex: 0x38BDF8)
        case .violet: Color(hex: 0xA78BFA)
        }
    }
}
