 import SwiftUI

struct PastelBackground: View {
    var focus: Int = 0
    @State private var breathe = false

    var body: some View {
        let spots: [SIMD2<Float>] = [[0.35, 0.40], [0.65, 0.45], [0.50, 0.65]]
        let base = spots[abs(focus) % spots.count]
        let center: SIMD2<Float> = breathe ? base + [0.06, -0.05] : base

        ZStack {
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], center, [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    .pastelBlue, .pastelBlue, .white,
                    .pastelBlue, .pastelMint, .pastelBlue,
                    .pastelMint, .white, .pastelMint
                ]
            )
            FloatingFood()
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.8), value: focus)
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }
}
