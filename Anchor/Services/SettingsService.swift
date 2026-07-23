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

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        calculationMethod = PrayerCalculationMethod(rawValue: defaults.string(forKey: Keys.calculationMethod) ?? "") ?? .muslimWorldLeague
        madhab = PrayerMadhab(rawValue: defaults.string(forKey: Keys.madhab) ?? "") ?? .shafi
        appearance = AppAppearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
    }

    private enum Keys {
        static let calculationMethod = "settings.calculationMethod"
        static let madhab = "settings.madhab"
        static let appearance = "settings.appearance"
    }
}
