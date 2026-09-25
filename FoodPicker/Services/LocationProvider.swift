import CoreLocation

@MainActor
final class LocationProvider: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?
    private var timeout: Task<Void, Never>?
    private(set) var isDenied = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation() async -> CLLocationCoordinate2D? {
        finish(nil)  // มีคำขอเก่าค้างอยู่ ให้จบก่อน ไม่งั้น continuation เดิมจะไม่ถูก resume
        return await withCheckedContinuation { cont in
            continuation = cont
            isDenied = false

            switch manager.authorizationStatus {
            case .notDetermined: manager.requestWhenInUseAuthorization()
            case .denied, .restricted: finish(nil, denied: true)
                return
            default: manager.requestLocation()
            }

            timeout = Task {
                try? await Task.sleep(for: .seconds(12))
                guard !Task.isCancelled else { return }
                self.finish(nil)
            }
        }
    }

    // ยกเลิก timeout ของรอบนี้ทุกครั้ง — ถ้าปล่อยไว้ จะไปตัดจบคำขอรอบถัดไป (เช่น กด "ลองใหม่") ก่อนเวลา
    private func finish(_ coord: CLLocationCoordinate2D?, denied: Bool = false) {
        timeout?.cancel()
        timeout = nil
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
            case .authorizedWhenInUse, .authorizedAlways: self.manager.requestLocation()
            case .denied, .restricted: self.finish(nil, denied: true)
            default: break
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
