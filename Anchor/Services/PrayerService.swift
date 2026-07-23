import Foundation
import CoreLocation
import Adhan

struct PrayerService {
    var calculationMethod: PrayerCalculationMethod = .muslimWorldLeague
    var madhab: PrayerMadhab = .shafi

    func time(for prayer: PrayerName, coordinate: CLLocationCoordinate2D, on date: Date, calendar: Calendar = .current) -> Date? {
        let coordinates = Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)
        var params = adhanMethod.params
        params.madhab = adhanMadhab

        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let prayerTimes = PrayerTimes(coordinates: coordinates, date: components, calculationParameters: params) else {
            return nil
        }

        switch prayer {
        case .fajr: return prayerTimes.fajr
        case .dhuhr: return prayerTimes.dhuhr
        case .asr: return prayerTimes.asr
        case .maghrib: return prayerTimes.maghrib
        case .isha: return prayerTimes.isha
        }
    }

    private var adhanMethod: CalculationMethod {
        switch calculationMethod {
        case .muslimWorldLeague: .muslimWorldLeague
        case .egyptian: .egyptian
        case .karachi: .karachi
        case .ummAlQura: .ummAlQura
        case .dubai: .dubai
        case .moonsightingCommittee: .moonsightingCommittee
        case .northAmerica: .northAmerica
        case .kuwait: .kuwait
        case .qatar: .qatar
        case .singapore: .singapore
        case .tehran: .tehran
        case .turkey: .turkey
        case .other: .other
        }
    }

    private var adhanMadhab: Madhab {
        switch madhab {
        case .shafi: .shafi
        case .hanafi: .hanafi
        }
    }
}
