import SwiftUI

struct ContentView: View {
    @Environment(MenuStore.self) private var store
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var isLoading = true

    var body: some View {
        ZStack {
            PickerScreen()
                .fullScreenCover(isPresented: Binding(
                    get: { !isLoading && !hasSeenOnboarding },
                    set: { hasSeenOnboarding = !$0 }
                )) {
                    OnboardingView { hasSeenOnboarding = true }
                }

            if isLoading {
                LoadingView()
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
                    .zIndex(1)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(.easeInOut(duration: 0.5)) { isLoading = false }
        }
        .onOpenURL { store.handleOpenURL($0) }
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
        .environment(MenuStore())
}
