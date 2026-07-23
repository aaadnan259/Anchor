import Foundation

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

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        calculationMethod = PrayerCalculationMethod(rawValue: defaults.string(forKey: Keys.calculationMethod) ?? "") ?? .muslimWorldLeague
        madhab = PrayerMadhab(rawValue: defaults.string(forKey: Keys.madhab) ?? "") ?? .shafi
        appearance = AppAppearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
    }

    private enum Keys {
        static let calculationMethod = "settings.calculationMethod"
        static let madhab = "settings.madhab"
        static let appearance = "settings.appearance"
        static let hasCompletedOnboarding = "settings.hasCompletedOnboarding"
    }
}
