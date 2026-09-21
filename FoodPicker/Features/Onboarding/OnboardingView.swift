import SwiftUI

struct OnboardingPage: Identifiable {
    let id: Int
    let symbol: String
    let title: String
    let subtitle: String
}

struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var page = 0

    private let pages = [
        OnboardingPage(id: 0, symbol: "fork.knife",
                       title: "คิดไม่ออกว่ากินอะไร",
                       subtitle: "ให้แอปเลือกให้ จาก \(builtInFoods.count) เมนู ทั้งไทยและต่างชาติ"),
        OnboardingPage(id: 1, symbol: "dice.fill",
                       title: "กดสุ่ม แล้วลุ้นเลย",
                       subtitle: "เมนูจะหมุนเหมือนตู้สล็อต ก่อนหยุดที่จานของคุณ"),
        OnboardingPage(id: 2, symbol: "heart.fill",
                       title: "เก็บเมนูที่ชอบไว้",
                       subtitle: "กดหัวใจ แล้วสุ่มเฉพาะเมนูโปรดได้")
    ]

    private var isLastPage: Bool { page == pages.count - 1 }

    var body: some View {
        ZStack {
            PastelBackground(focus: page)

            VStack(spacing: 28) {
                HStack {
                    Spacer()
                    if !isLastPage {
                        Button("ข้าม", action: onFinish)
                            .buttonStyle(.glass)
                    }
                }
                .frame(height: 44)
                .padding(.horizontal)

                TabView(selection: $page) {
                    ForEach(pages) { item in
                        VStack(spacing: 28) {
                            Image(systemName: item.symbol)
                                .font(.system(size: 76, weight: .semibold))
                                .foregroundStyle(item.id == 2 ? Color.pink : Color.ink)
                                .symbolEffect(.bounce, value: page)
                                .frame(width: 176, height: 176)
                                .glassEffect(.regular, in: .circle)

                            Text(item.title)
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .multilineTextAlignment(.center)

                            Text(item.subtitle)
                                .font(.title3)
                                .foregroundStyle(Color.ink.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .tag(item.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(pages) { item in
                        Capsule()
                            .fill(Color.ink.opacity(item.id == page ? 1 : 0.25))
                            .frame(width: item.id == page ? 28 : 8, height: 8)
                    }
                }
                .animation(.spring, value: page)

                Button {
                    if isLastPage {
                        onFinish()
                    } else {
                        withAnimation { page += 1 }
                    }
                } label: {
                    Text(isLastPage ? "เริ่มต้นใช้งาน" : "ถัดไป")
                        .font(.headline)
                        .foregroundStyle(Color.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.glassProminent)
                .tint(Color.softAqua)
                .controlSize(.large)
                .phaseAnimator([false, true]) { content, phase in
                    content.scaleEffect(isLastPage && phase ? 1.04 : 1)
                } animation: { _ in
                    .easeInOut(duration: 0.9)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
        .foregroundStyle(Color.ink)
    }
}
