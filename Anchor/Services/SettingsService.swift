import Foundation
import SwiftUI

@MainActor
@Observable
final class SettingsService {
    private let defaults: UserDefaults

    var calculationMethod: PrayerCalculationMethod {
        didSet { defaults.set(calculationMethod.rawValue, forKey: Keys.calculationMethod) }
    }

    var madhab: PrayerMadhab {
        didSet { defaults.set(madhab.rawValue, forKey: Keys.madhab) }
    }

    var appearance: AppAppearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    var accentColor: AccentColor {
        didSet { defaults.set(accentColor.rawValue, forKey: Keys.accentColor) }
    }

    var customAccentColorHex: UInt? {
        didSet {
            if let customAccentColorHex {
                defaults.set(Int(customAccentColorHex), forKey: Keys.customAccentColorHex)
            } else {
                defaults.removeObject(forKey: Keys.customAccentColorHex)
            }
        }
    }

    /// The app-wide tint: an exact custom color when set, otherwise the curated `accentColor`.
    var effectiveAccentColor: Color {
        customAccentColorHex.map { Color(hex: $0) } ?? accentColor.color
    }

    var biometricLockEnabled: Bool {
        didSet { defaults.set(biometricLockEnabled, forKey: Keys.biometricLockEnabled) }
    }

    var smartRemindersEnabled: Bool {
        didSet { defaults.set(smartRemindersEnabled, forKey: Keys.smartRemindersEnabled) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        calculationMethod = PrayerCalculationMethod(rawValue: defaults.string(forKey: Keys.calculationMethod) ?? "") ?? .muslimWorldLeague
        madhab = PrayerMadhab(rawValue: defaults.string(forKey: Keys.madhab) ?? "") ?? .shafi
        appearance = AppAppearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        accentColor = AccentColor(rawValue: defaults.string(forKey: Keys.accentColor) ?? "") ?? .indigo
        customAccentColorHex = (defaults.object(forKey: Keys.customAccentColorHex) as? Int).map(UInt.init)
        biometricLockEnabled = defaults.bool(forKey: Keys.biometricLockEnabled)
        smartRemindersEnabled = defaults.bool(forKey: Keys.smartRemindersEnabled)
    }

    private enum Keys {
        static let calculationMethod = "settings.calculationMethod"
        static let madhab = "settings.madhab"
        static let appearance = "settings.appearance"
        static let hasCompletedOnboarding = "settings.hasCompletedOnboarding"
        static let accentColor = "settings.accentColor"
        static let customAccentColorHex = "settings.customAccentColorHex"
        static let biometricLockEnabled = "settings.biometricLockEnabled"
        static let smartRemindersEnabled = "settings.smartRemindersEnabled"
    }
}
