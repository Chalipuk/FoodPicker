import SwiftUI

struct LoadingView: View {
    @State private var spin = false
    @State private var dot = 0

    var body: some View {
        ZStack {
            PastelBackground()

            VStack(spacing: 28) {
                Image(systemName: "dice.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .frame(width: 150, height: 150)
                    .glassEffect(.regular, in: .circle)

                Text("วันนี้กินอะไรดี?")
                    .font(.system(.title, design: .rounded, weight: .heavy))

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .frame(width: 10, height: 10)
                            .opacity(dot == i ? 1 : 0.25)
                            .scaleEffect(dot == i ? 1.25 : 1)
                    }
                }
            }
            .foregroundStyle(Color.ink)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                spin = true
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(280))
                withAnimation(.easeInOut(duration: 0.2)) { dot = (dot + 1) % 3 }
            }
        }
    }
}
