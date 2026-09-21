import SwiftUI

struct FloatingFood: View {
    private let emojis = ["🍜", "🍣", "🌶️", "🍰", "🥟", "🍕", "🍡", "🥭"]
    @State private var float = false

    var body: some View {
        GeometryReader { geo in
            ForEach(Array(emojis.enumerated()), id: \.offset) { i, emoji in
                let x = geo.size.width * (0.08 + 0.84 * CGFloat(i * 37 % 100) / 100)
                let y = geo.size.height * (0.08 + 0.84 * CGFloat(i * 53 % 100) / 100)

                Text(emoji)
                    .font(.system(size: 34))
                    .opacity(0.22)
                    .rotationEffect(.degrees(float ? 12 : -12))
                    .position(x: x, y: y + (float ? -16 : 16))
                    .animation(
                        .easeInOut(duration: 3 + Double(i % 3))
                            .repeatForever(autoreverses: true),
                        value: float
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear { float = true }
    }
}
