import CoreLocation

@MainActor
final class LocationProvider: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?
    private(set) var isDenied = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation() async -> CLLocationCoordinate2D? {
        await withCheckedContinuation { cont in
            continuation = cont
            isDenied = false

            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .denied, .restricted:
                finish(nil, denied: true)
                return
            default:
                manager.requestLocation()
            }

            Task {
                try? await Task.sleep(for: .seconds(12))
                self.finish(nil)
            }
        }
    }

    private func finish(_ coord: CLLocationCoordinate2D?, denied: Bool = false) {
        guard let cont = continuation else { return }
        continuation = nil
        isDenied = denied
        cont.resume(returning: coord)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            guard self.continuation != nil else { return }
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.manager.requestLocation()
            case .denied, .restricted:
                self.finish(nil, denied: true)
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coord = locations.last?.coordinate
        Task { @MainActor in self.finish(coord) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.finish(nil) }
    }
}
