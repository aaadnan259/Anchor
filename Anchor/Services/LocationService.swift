import Foundation
import CoreLocation

@MainActor
@Observable
final class LocationService {
    private let manager = CLLocationManager()
    private(set) var lastKnownCoordinate: CLLocationCoordinate2D?

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    func requestAuthorizationIfNeeded() {
        guard manager.authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    func refreshLocation() async {
        guard manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways else { return }
        do {
            for try await update in CLLocationUpdate.liveUpdates() {
                if let location = update.location {
                    lastKnownCoordinate = location.coordinate
                    return
                }
            }
        } catch {
            // Location temporarily unavailable; keep the last known coordinate.
        }
    }
}
