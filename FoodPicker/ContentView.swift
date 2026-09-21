import SwiftUI

// MARK: - สีของแอป (ฟ้าพาสเทล + มิ้นต์)
extension Color {
    static let pastelBlue = Color(red: 0.659, green: 0.847, blue: 0.941)  // #A8D8F0 ฟ้าพาสเทล
    static let pastelMint = Color(red: 0.741, green: 0.922, blue: 0.839)  // #BDEBD6 มิ้นต์
    static let softAqua   = Color(red: 0.490, green: 0.780, blue: 0.851)  // #7DC7D9 ปุ่มหลัก (ฟ้าอมเขียว สว่างขึ้น)
    static let ink        = Color(red: 0.122, green: 0.227, blue: 0.373)  // #1F3A5F ตัวอักษร
}

// MARK: - ข้อมูลเมนู
struct Food: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let emoji: String
    let tag: String

    init(_ name: String, _ emoji: String, _ tag: String) {
        self.name = name
        self.emoji = emoji
        self.tag = tag
    }
}

let foodCategories = ["จานเดียว", "เส้น", "ต้ม/แกง", "อีสาน", "เหนือ", "ใต้",
                      "ปิ้งย่าง/ทะเล", "ญี่ปุ่น", "เกาหลี", "จีน", "ฝรั่ง", "ของหวาน"]

let allFoods: [Food] = [
    // จานเดียว
    Food("ผัดกะเพราหมูสับ", "🌶️", "จานเดียว"),
    Food("ข้าวมันไก่", "🍗", "จานเดียว"),
    Food("ข้าวผัดกุ้ง", "🍤", "จานเดียว"),
    Food("ข้าวขาหมู", "🍖", "จานเดียว"),
    Food("ข้าวหมูแดง", "🥩", "จานเดียว"),
    Food("ข้าวไข่เจียว", "🍳", "จานเดียว"),
    Food("ข้าวหมูกระเทียม", "🧄", "จานเดียว"),
    Food("ข้าวคลุกกะปิ", "🥭", "จานเดียว"),
    Food("ข้าวหน้าเป็ด", "🦆", "จานเดียว"),
    Food("ข้าวไข่ข้นกุ้ง", "🥚", "จานเดียว"),
    // เส้น
    Food("ก๋วยเตี๋ยวเรือ", "🍜", "เส้น"),
    Food("ผัดไทยกุ้งสด", "🥢", "เส้น"),
    Food("ผัดซีอิ๊ว", "🥬", "เส้น"),
    Food("ราดหน้า", "🥣", "เส้น"),
    Food("บะหมี่เกี๊ยว", "🥟", "เส้น"),
    Food("เย็นตาโฟ", "🍥", "เส้น"),
    Food("ก๋วยจั๊บ", "🍲", "เส้น"),
    Food("สุกี้น้ำ", "🍲", "เส้น"),
    Food("ขนมจีนน้ำยา", "🍝", "เส้น"),
    // ต้ม/แกง
    Food("ต้มยำกุ้ง", "🦐", "ต้ม/แกง"),
    Food("ต้มข่าไก่", "🥥", "ต้ม/แกง"),
    Food("แกงเขียวหวาน", "🍛", "ต้ม/แกง"),
    Food("แกงส้มชะอม", "🐟", "ต้ม/แกง"),
    Food("พะแนงหมู", "🥘", "ต้ม/แกง"),
    Food("ต้มจืดเต้าหู้", "🍵", "ต้ม/แกง"),
    Food("แกงมัสมั่น", "🥔", "ต้ม/แกง"),
    Food("ต้มแซ่บกระดูกอ่อน", "🌶️", "ต้ม/แกง"),
    // อีสาน
    Food("ส้มตำไทย", "🥗", "อีสาน"),
    Food("ส้มตำปูปลาร้า", "🦀", "อีสาน"),
    Food("ลาบหมู", "🌿", "อีสาน"),
    Food("น้ำตกหมู", "🥩", "อีสาน"),
    Food("ไก่ย่าง", "🍗", "อีสาน"),
    Food("คอหมูย่าง", "🔥", "อีสาน"),
    Food("ซุปหน่อไม้", "🎋", "อีสาน"),
    Food("จิ้มจุ่ม", "🍲", "อีสาน"),
    // เหนือ
    Food("ข้าวซอย", "🍛", "เหนือ"),
    Food("ขนมจีนน้ำเงี้ยว", "🍅", "เหนือ"),
    Food("น้ำพริกหนุ่ม", "🫑", "เหนือ"),
    Food("ไส้อั่ว", "🌭", "เหนือ"),
    Food("แกงฮังเล", "🍖", "เหนือ"),
    // ใต้
    Food("แกงไตปลา", "🐟", "ใต้"),
    Food("ข้าวยำ", "🌿", "ใต้"),
    Food("คั่วกลิ้ง", "🌶️", "ใต้"),
    Food("แกงเหลือง", "🍲", "ใต้"),
    Food("ผัดสะตอ", "🫛", "ใต้"),
    // ปิ้งย่าง/ทะเล
    Food("หมูกระทะ", "🥓", "ปิ้งย่าง/ทะเล"),
    Food("ปูผัดผงกะหรี่", "🦀", "ปิ้งย่าง/ทะเล"),
    Food("กุ้งเผา", "🦐", "ปิ้งย่าง/ทะเล"),
    Food("ปลาเผาเกลือ", "🐟", "ปิ้งย่าง/ทะเล"),
    Food("หอยทอด", "🦪", "ปิ้งย่าง/ทะเล"),
    // ญี่ปุ่น
    Food("ซูชิ", "🍣", "ญี่ปุ่น"),
    Food("ราเมง", "🍜", "ญี่ปุ่น"),
    Food("ข้าวแกงกะหรี่", "🍛", "ญี่ปุ่น"),
    Food("ทงคัตสึ", "🐷", "ญี่ปุ่น"),
    Food("ชาบู", "🍲", "ญี่ปุ่น"),
    Food("ทาโกะยากิ", "🐙", "ญี่ปุ่น"),
    // เกาหลี
    Food("บิบิมบับ", "🍚", "เกาหลี"),
    Food("ต็อกบกกี", "🌶️", "เกาหลี"),
    Food("หมูย่างเกาหลี", "🥓", "เกาหลี"),
    Food("ไก่ทอดเกาหลี", "🍗", "เกาหลี"),
    // จีน
    Food("ติ่มซำ", "🥟", "จีน"),
    Food("เป็ดปักกิ่ง", "🦆", "จีน"),
    Food("หม่าล่า", "🌶️", "จีน"),
    Food("ข้าวต้มปลา", "🍚", "จีน"),
    // ฝรั่ง
    Food("พิซซ่า", "🍕", "ฝรั่ง"),
    Food("เบอร์เกอร์", "🍔", "ฝรั่ง"),
    Food("สปาเกตตีคาโบนารา", "🍝", "ฝรั่ง"),
    Food("สเต๊กหมู", "🥩", "ฝรั่ง"),
    Food("แซนด์วิช", "🥪", "ฝรั่ง"),
    Food("สลัดไก่", "🥗", "ฝรั่ง"),
    // ของหวาน
    Food("ข้าวเหนียวมะม่วง", "🥭", "ของหวาน"),
    Food("บิงซู", "🍧", "ของหวาน"),
    Food("บัวลอย", "🍡", "ของหวาน"),
    Food("โรตีกล้วย", "🍌", "ของหวาน"),
    Food("ไอศกรีม", "🍨", "ของหวาน"),
    Food("ขนมปังปิ้ง", "🍞", "ของหวาน"),
    Food("เค้กช็อกโกแลต", "🍰", "ของหวาน")
]

// MARK: - หน้าหลัก (เปิดหน้าแนะนำครั้งแรกอัตโนมัติ)
struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        PickerScreen()
            .fullScreenCover(isPresented: Binding(
                get: { !hasSeenOnboarding },
                set: { hasSeenOnboarding = !$0 }
            )) {
                OnboardingView { hasSeenOnboarding = true }
            }
            .preferredColorScheme(.light)
    }
}

// MARK: - พื้นหลังฟ้า + มิ้นต์ ที่ขยับเหมือนหายใจ
struct PastelBackground: View {
    var focus: Int = 0          // ค่านี้เปลี่ยน ก้อนสีมิ้นต์จะเลื่อนตำแหน่ง
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

// MARK: - อีโมจิอาหารลอยไปมาเบา ๆ ที่พื้นหลัง
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

// MARK: - หน้าแนะนำแอป (Onboarding)
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
                       subtitle: "ให้แอปเลือกให้ จาก \(allFoods.count) เมนู ทั้งไทยและต่างชาติ"),
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

                // จุดบอกหน้า
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
                // หน้าสุดท้าย ปุ่มจะเต้นเบา ๆ ชวนกด
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

// MARK: - หน้าสุ่มเมนู
struct PickerScreen: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("favorites") private var favoritesRaw = ""

    @State private var current: Food?
    @State private var rolling: Food?          // เมนูที่กำลังหมุนผ่าน
    @State private var history: [Food] = []
    @State private var selectedTag = "ทั้งหมด"
    @State private var isSpinning = false
    @State private var tick = 0                // สั่นเบา ๆ ทุกครั้งที่หมุนผ่าน
    @State private var landed = 0              // สั่นแรงตอนหยุด

    private var favorites: Set<String> {
        Set(favoritesRaw.split(separator: "|").map(String.init))
    }

    private var tags: [String] {
        (favorites.isEmpty ? ["ทั้งหมด"] : ["ทั้งหมด", "ที่ชอบ"]) + foodCategories
    }

    private var pool: [Food] {
        switch selectedTag {
        case "ทั้งหมด": return allFoods
        case "ที่ชอบ": return allFoods.filter { favorites.contains($0.name) }
        default: return allFoods.filter { $0.tag == selectedTag }
        }
    }

    private var shown: Food? { rolling ?? current }

    var body: some View {
        ZStack {
            PastelBackground(focus: landed)

            ScrollView {
                VStack(spacing: 22) {
                    header
                    tagBar
                    resultCard
                    spinButton
                    if !history.isEmpty { historySection }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(Color.ink)
        .sensoryFeedback(.selection, trigger: tick)
        .sensoryFeedback(.success, trigger: landed)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("วันนี้กินอะไรดี?")
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                Text("มี \(allFoods.count) เมนูให้สุ่ม")
                    .font(.subheadline)
                    .foregroundStyle(Color.ink.opacity(0.6))
            }
            Spacer()
            Button("ดูคำแนะนำ", systemImage: "questionmark") {
                hasSeenOnboarding = false
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.glass)
        }
    }

    private var tagBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Button {
                        withAnimation(.snappy) { selectedTag = tag }
                    } label: {
                        Text(tag == "ที่ชอบ" ? "❤️ ที่ชอบ" : tag)
                            .fontWeight(selectedTag == tag ? .bold : .regular)
                    }
                    .buttonStyle(.glass)
                    .tint(selectedTag == tag ? Color.pastelMint : nil)
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }

    // จุดเด่นของแอป: จานที่หมุนแบบตู้สล็อต
    private var resultCard: some View {
        VStack(spacing: 14) {
            ZStack {
                if let food = shown {
                    VStack(spacing: 12) {
                        Text(food.emoji)
                            .font(.system(size: 110))
                        Text(food.name)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)
                    }
                    .id(food.id)
                    .transition(.push(from: .bottom))
                } else {
                    VStack(spacing: 12) {
                        Text("🍽️")
                            .font(.system(size: 110))
                        Text(pool.isEmpty ? "ยังไม่มีเมนูที่ชอบ\nกดหัวใจที่เมนูก่อนนะ" : "กดปุ่มด้านล่างเพื่อสุ่ม")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(height: 200)
            .clipped()

            if let food = current, !isSpinning {
                HStack(spacing: 10) {
                    Text(food.tag)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .glassEffect(.regular.tint(Color.pastelMint.opacity(0.6)), in: .capsule)

                    Button {
                        toggleFavorite(food)
                    } label: {
                        Image(systemName: favorites.contains(food.name) ? "heart.fill" : "heart")
                            .foregroundStyle(.pink)
                            .symbolEffect(.bounce, value: favoritesRaw)
                    }
                    .buttonStyle(.glass)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .glassEffect(.regular, in: .rect(cornerRadius: 36))
    }

    private var spinButton: some View {
        Button(action: spin) {
            Label(isSpinning ? "กำลังสุ่ม..." : "สุ่มเมนู", systemImage: "dice.fill")
                .font(.title3.bold())
                .foregroundStyle(Color.ink)
                .symbolEffect(.bounce, value: tick)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.glassProminent)
        .tint(Color.softAqua)
        .controlSize(.large)
        .disabled(isSpinning || pool.isEmpty)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("สุ่มล่าสุด")
                .font(.headline)
                .padding(.leading, 4)

            ForEach(Array(history.enumerated()), id: \.offset) { _, food in
                HStack(spacing: 12) {
                    Text(food.emoji).font(.title2)
                    Text(food.name).font(.body.weight(.medium))
                    Spacer()
                    if favorites.contains(food.name) {
                        Image(systemName: "heart.fill").foregroundStyle(.pink)
                    }
                    Text(food.tag)
                        .font(.caption)
                        .foregroundStyle(Color.ink.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassEffect(.regular, in: .rect(cornerRadius: 18))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // หมุนผ่านหลายเมนู เร็วแล้วค่อย ๆ ช้าลง ก่อนหยุด
    private func spin() {
        guard !isSpinning, !pool.isEmpty else { return }
        isSpinning = true
        let candidates = pool

        Task {
            for step in 0..<16 {
                withAnimation(.easeOut(duration: 0.08)) {
                    rolling = candidates.randomElement()
                }
                tick += 1
                try? await Task.sleep(for: .milliseconds(50 + step * step))
            }

            var next = candidates.randomElement()
            while candidates.count > 1 && next == current {
                next = candidates.randomElement()
            }

            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                rolling = nil
                current = next
                isSpinning = false
                if let next {
                    history.insert(next, at: 0)
                    if history.count > 5 { history.removeLast() }
                }
            }
            landed += 1
        }
    }

    private func toggleFavorite(_ food: Food) {
        var set = favorites
        if set.contains(food.name) {
            set.remove(food.name)
        } else {
            set.insert(food.name)
        }
        favoritesRaw = set.sorted().joined(separator: "|")
    }
}

#Preview {
    ContentView()
}
