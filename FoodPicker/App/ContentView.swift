import SwiftUI

struct ContentView: View {
    @Environment(MenuStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 1.08)))
                    .zIndex(1)
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 300 : 1250))
            withAnimation(.easeInOut(duration: 0.45)) { isLoading = false }
        }
        .onOpenURL { store.handleOpenURL($0) }
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
        .environment(MenuStore())
}
