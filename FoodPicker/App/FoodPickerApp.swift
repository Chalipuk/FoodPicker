import SwiftUI

@main
struct FoodPickerApp: App {
    @State private var store = MenuStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
