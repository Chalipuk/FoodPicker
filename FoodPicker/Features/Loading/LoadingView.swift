import SwiftUI

// เฟรมแรกต้องเหมือน Launch Screen เป๊ะ (พื้น LaunchBackground + LaunchLogo 150pt กลางจอ)
// ผู้ใช้จะเห็นเป็นภาพเดียวกันที่เริ่มขยับ ไม่มีรอยกระตุก
private struct DiceToss {
    var angle: Double = 0
    var scale: Double = 1
    var lift: Double = 0
}

struct LoadingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false
    @State private var tossed = false

    var body: some View {
        ZStack {
            Color(.launchBackground)

            PastelBackground()
                .opacity(revealed ? 1 : 0)

            Image(.launchLogo)
                .resizable()
                .frame(width: 150, height: 150)
                .keyframeAnimator(initialValue: DiceToss(), trigger: tossed) { logo, toss in
                    logo
                        .rotationEffect(.degrees(toss.angle))
                        .scaleEffect(toss.scale)
                        .offset(y: toss.lift)
                } keyframes: { _ in
                    // ย่อตัวเตรียมโยน → ลอยขึ้นพร้อมหมุน 1 รอบ → ตกลงมาเด้ง
                    KeyframeTrack(\.angle) {
                        CubicKeyframe(-18, duration: 0.15)
                        SpringKeyframe(360, duration: 0.6, spring: .bouncy)
                    }
                    KeyframeTrack(\.scale) {
                        CubicKeyframe(0.9, duration: 0.15)
                        CubicKeyframe(1.15, duration: 0.25)
                        SpringKeyframe(1, duration: 0.45, spring: .bouncy)
                    }
                    KeyframeTrack(\.lift) {
                        CubicKeyframe(6, duration: 0.15)
                        CubicKeyframe(-34, duration: 0.25)
                        SpringKeyframe(0, duration: 0.5, spring: .bouncy(extraBounce: 0.25))
                    }
                }
                .shadow(color: Color.ink.opacity(revealed ? 0.2 : 0), radius: 20, y: 10)

            VStack(spacing: 6) {
                Text("วันนี้กินอะไรดี?")
                    .font(.system(.title, design: .rounded, weight: .heavy))
                Text("กำลังเตรียมเมนูให้...")
                    .font(.subheadline)
                    .foregroundStyle(Color.ink.opacity(0.6))
            }
            .foregroundStyle(Color.ink)
            .offset(y: revealed ? 140 : 160)
            .opacity(revealed ? 1 : 0)
        }
        .ignoresSafeArea()
        .task {
            guard !reduceMotion else {
                revealed = true
                return
            }
            tossed = true
            withAnimation(.easeOut(duration: 0.55)) { revealed = true }
        }
    }
}

#Preview {
    LoadingView()
}
