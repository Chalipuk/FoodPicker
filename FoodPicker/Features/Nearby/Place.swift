import MapKit

struct Place: Identifiable {
    let id = UUID()
    let item: MKMapItem
    let distance: CLLocationDistance

    var name: String { item.name ?? "ไม่ทราบชื่อร้าน" }
    var coordinate: CLLocationCoordinate2D { item.location.coordinate }

    var distanceText: String {
        distance < 1000
            ? "\(Int(distance)) ม."
            : String(format: "%.1f กม.", distance / 1000)
    }
}
