import SwiftUI

struct FloatingFood: View {
    private let emojis = ["🍜", "🍣", "🌶️", "🍰", "🥟", "🍕", "🍡", "🥭", "🍔", "🧋", "🍙", "🥗"]
    @State private var float = false

    var body: some View {
        GeometryReader { geo in
            ForEach(Array(emojis.enumerated()), id: \.offset) { i, emoji in
                // ไล่ลงทีละแถวให้ครอบคลุมทั้งจอ ส่วนแนวนอนกระจายด้วยอัตราส่วนทองคำจะได้ไม่เรียงเป็นเส้น
                let x = geo.size.width * (0.08 + 0.84 * (Double(i) * 0.618).truncatingRemainder(dividingBy: 1))
                let y = geo.size.height * (0.05 + 0.9 * (Double(i) + 0.5) / Double(emojis.count))

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
