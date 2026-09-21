import SwiftUI
import MapKit

struct NearbyView: View {
    let food: Food

    enum Status: Equatable {
        case locating, searching, done, denied, failed
    }

    @Environment(\.dismiss) private var dismiss
    @State private var locator = LocationProvider()
    @State private var camera: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var places: [Place] = []
    @State private var status: Status = .locating

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Map(position: $camera) {
                    UserAnnotation()
                    ForEach(places) { place in
                        Marker(place.name, systemImage: "fork.knife", coordinate: place.coordinate)
                            .tint(Color.ink)
                    }
                }
                .mapControls { MapUserLocationButton() }
                .frame(height: 300)

                content
                    .frame(maxHeight: .infinity)
            }
            .navigationTitle("\(food.emoji) \(food.name) ใกล้ฉัน")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("ปิด") { dismiss() }
                }
            }
        }
        .tint(Color.ink)
        .task { await load() }
    }

    @ViewBuilder
    private var content: some View {
        switch status {
        case .locating:
            message("กำลังหาตำแหน่งของคุณ...", loading: true)
        case .searching:
            message("กำลังค้นหาร้าน\(food.name)...", loading: true)
        case .denied:
            VStack(spacing: 14) {
                message("แอปยังไม่ได้รับอนุญาตให้ใช้ตำแหน่ง", loading: false)
                Link("เปิดการตั้งค่า", destination: URL(string: UIApplication.openSettingsURLString)!)
                    .buttonStyle(.glassProminent)
                    .tint(Color.softAqua)
            }
        case .failed:
            VStack(spacing: 14) {
                message("หาตำแหน่งไม่ได้ ลองใหม่อีกครั้ง", loading: false)
                Button("ลองใหม่") { Task { await load() } }
                    .buttonStyle(.glass)
            }
        case .done:
            if places.isEmpty {
                message("ไม่เจอร้าน\(food.name) ในระยะ 5 กม.\nลองสุ่มเมนูอื่นดูนะ", loading: false)
            } else {
                List(places) { place in
                    Button {
                        place.item.openInMaps(launchOptions: [
                            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                        ])
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.softAqua)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(place.name)
                                    .font(.body.weight(.semibold))
                                Text(place.distanceText)
                                    .font(.caption)
                                    .foregroundStyle(Color.ink.opacity(0.6))
                            }
                            Spacer()
                            Label("นำทาง", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                                .labelStyle(.iconOnly)
                                .font(.title2)
                        }
                        .foregroundStyle(Color.ink)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func message(_ text: String, loading: Bool) -> some View {
        VStack(spacing: 12) {
            if loading { ProgressView() }
            Text(text)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.ink.opacity(0.7))
        }
        .padding(24)
    }

    private func load() async {
        status = .locating
        guard let here = await locator.requestLocation() else {
            status = locator.isDenied ? .denied : .failed
            return
        }

        status = .searching
        let items = await searchPlaces(food.name, near: here)
        let me = CLLocation(latitude: here.latitude, longitude: here.longitude)

        places = items
            .map { item in
                let c = item.location.coordinate
                let d = me.distance(from: CLLocation(latitude: c.latitude, longitude: c.longitude))
                return Place(item: item, distance: d)
            }
            .sorted { $0.distance < $1.distance }

        withAnimation { camera = .automatic }
        status = .done
    }

    private func searchPlaces(_ query: String, near c: CLLocationCoordinate2D) async -> [MKMapItem] {
        func request(filtered: Bool) -> MKLocalSearch.Request {
            let r = MKLocalSearch.Request()
            r.naturalLanguageQuery = query
            r.region = MKCoordinateRegion(center: c, latitudinalMeters: 5000, longitudinalMeters: 5000)
            r.resultTypes = .pointOfInterest
            if filtered {
                r.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant, .cafe, .bakery])
            }
            return r
        }

        if let items = try? await MKLocalSearch(request: request(filtered: true)).start().mapItems,
           !items.isEmpty {
            return items
        }
        return (try? await MKLocalSearch(request: request(filtered: false)).start().mapItems) ?? []
    }
}
