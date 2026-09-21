import SwiftUI

struct PickerScreen: View {
    @Environment(MenuStore.self) private var store
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("favorites") private var favoritesRaw = ""
    @AppStorage("excluded") private var excludedRaw = ""
    @AppStorage("mode") private var modeRaw = MealMode.food.rawValue

    @State private var current: Food?
    @State private var rolling: Food?
    @State private var selectedTag = "ทั้งหมด"
    @State private var selectedSub: String?
    @State private var isSpinning = false
    @State private var tick = 0
    @State private var landed = 0
    @State private var showMenuList = false
    @State private var nearbyFood: Food?
    @State private var showFilters = false
    @State private var showHistory = false
    @State private var showGroups = false
    @State private var showMealLog = false
    @State private var loggedFoodID: Food.ID?
    @State private var showJayAlert = false
    // ดึงเพื่อเริ่มใหม่ = ซ่อน "สุ่มล่าสุด" บนหน้านี้ แต่ไม่ลบประวัติที่บันทึกไว้
    @State private var recentSince = Date.distantPast

    private var favorites: Set<String> { NameSet.decode(favoritesRaw) }
    private var excluded: Set<String> { NameSet.decode(excludedRaw) }
    private var mode: MealMode { MealMode(rawValue: modeRaw) ?? .food }

    private var tags: [String] {
        var list = ["ทั้งหมด"]
        if store.allFoods.contains(where: { mode.contains($0) && favorites.contains($0.name) }) {
            list.append("ที่ชอบ")
        }
        if mode == .food {
            list += foodGroups.map(\.name)
        }
        return list
    }

    private var currentGroup: FoodGroup? {
        foodGroups.first { $0.name == selectedTag }
    }

    private var pool: [Food] {
        let rules = store.effectiveFilter
        let available = store.allFoods.filter {
            mode.contains($0) && !excluded.contains($0.name) && rules.allows($0, in: mode)
        }
        switch selectedTag {
        case "ทั้งหมด": return available
        case "ที่ชอบ": return available.filter { favorites.contains($0.name) }
        default:
            guard let group = currentGroup else { return available }
            let cats = selectedSub.map { [$0] } ?? group.categories
            return available.filter { cats.contains($0.tag) }
        }
    }

    private var shown: Food? { rolling ?? current }

    private var recentHistory: [HistoryEntry] {
        Array(store.history.lazy.filter { $0.date > recentSince }.prefix(5))
    }

    var body: some View {
        @Bindable var store = store

        ZStack {
            PastelBackground(focus: landed)

            ScrollView {
                VStack(spacing: 22) {
                    header
                    modePicker
                    tagBar
                    if let group = currentGroup, group.categories.count > 1 {
                        subBar(group)
                    }
                    if !statusLines.isEmpty { statusBanner }
                    resultCard
                    spinButton
                    todayCaloriesButton
                    if !recentHistory.isEmpty {
                        historySection
                    } else if !store.history.isEmpty {
                        Button("ดูประวัติการสุ่ม", systemImage: "clock") { showHistory = true }
                            .buttonStyle(.glass)
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
            .refreshable { await resetAll() }
        }
        .foregroundStyle(Color.ink)
        .sheet(isPresented: $showMenuList) { MenuListView(mode: mode).environment(store) }
        .sheet(isPresented: $showFilters) { FilterView(mode: mode).environment(store) }
        .sheet(isPresented: $showHistory) { HistoryView().environment(store) }
        .sheet(isPresented: $showGroups) { GroupsView().environment(store) }
        .sheet(isPresented: $showMealLog) { MealLogView().environment(store) }
        .sheet(item: $store.pendingProfile) { diner in
            ImportProfileView(diner: diner).environment(store)
        }
        .task {
            store.endJayIfOver()
            guard store.shouldAskJay else { return }
            try? await Task.sleep(for: .seconds(2))
            showJayAlert = true
        }
        .alert("ช่วงเทศกาลกินเจแล้ว 🟡", isPresented: $showJayAlert) {
            Button("เปิดมังสวิรัติ") { store.answerJay(turnOnVegetarian: true) }
            Button("ไม่เป็นไร", role: .cancel) { store.answerJay(turnOnVegetarian: false) }
        } message: {
            Text("ให้สุ่มเฉพาะเมนูมังสวิรัติไหม? แอปจะปิดให้เองเมื่อหมดเทศกาล")
        }
        .sheet(item: $nearbyFood) { food in NearbyView(food: food) }
        // ถ้าหมวดที่เลือกหายไป (เช่น เอาเมนูโปรดอันสุดท้ายออก) ให้กลับไป "ทั้งหมด" จะได้ไม่ค้าง
        .onChange(of: tags) {
            if !tags.contains(selectedTag) {
                selectedTag = "ทั้งหมด"
                selectedSub = nil
            }
        }
        .sensoryFeedback(.selection, trigger: tick)
        .sensoryFeedback(.success, trigger: landed)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(mode.question)
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .contentTransition(.opacity)
                Text("มี \(pool.count) เมนูให้สุ่ม · ดึงลงเพื่อเริ่มใหม่")
                    .font(.subheadline)
                    .foregroundStyle(Color.ink.opacity(0.6))
            }
            Spacer()
            Button("เมนูทั้งหมด", systemImage: "list.bullet") {
                showMenuList = true
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.glass)

            Button("ดูคำแนะนำ", systemImage: "questionmark") {
                hasSeenOnboarding = false
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.glass)
        }
    }

    private var modePicker: some View {
        Picker("โหมด", selection: Binding(
            get: { mode },
            set: { newMode in
                withAnimation(.snappy) {
                    modeRaw = newMode.rawValue
                    selectedTag = "ทั้งหมด"
                    selectedSub = nil
                    current = nil
                    rolling = nil
                }
                landed += 1
            }
        )) {
            ForEach(MealMode.allCases) { m in
                Text("\(m.emoji) \(m.rawValue)").tag(m)
            }
        }
        .pickerStyle(.segmented)
        .disabled(isSpinning)
    }

    private var tagBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                Button {
                    showFilters = true
                } label: {
                    Label(filterChipTitle, systemImage: "line.3.horizontal.decrease")
                        .fontWeight(store.filter.isActive ? .bold : .regular)
                }
                .buttonStyle(.glass)
                .tint(store.filter.isActive ? Color.pastelMint : nil)

                Button {
                    showGroups = true
                } label: {
                    Label(store.activeGroup.map { "\($0.name) \($0.members.count)" } ?? "กินด้วยกัน",
                          systemImage: "person.3")
                        .fontWeight(store.activeGroup != nil ? .bold : .regular)
                }
                .buttonStyle(.glass)
                .tint(store.activeGroup != nil ? Color.pastelMint : nil)

                ForEach(tags, id: \.self) { tag in
                    Button {
                        withAnimation(.snappy) {
                            selectedTag = tag
                            selectedSub = nil
                        }
                    } label: {
                        Text(chipLabel(tag))
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

    private var filterChipTitle: String {
        let count = store.filter.activeCount
        return count == 0 ? "ตัวกรอง" : "ตัวกรอง \(count)"
    }

    private var statusLines: [String] {
        var lines: [String] = []
        if let group = store.activeGroup {
            let labels = group.filter.dietLabels
            lines.append("👥 สุ่มให้ \(group.name) \(group.members.count) คน"
                         + (labels.isEmpty ? "" : " · " + labels.joined(separator: " ")))
        }
        if let days = store.budgetDaysLeft {
            if days == 0 {
                lines.append("🎉 เงินเดือนออกวันนี้ จัดเต็มได้!")
            } else if store.isBudgetTight {
                lines.append("💸 อีก \(days) วันเงินเดือนออก อดทนไว้ 🍜 · สุ่มเฉพาะ ฿")
            }
        }
        if !store.effectiveFilter.allergies.isEmpty {
            lines.append("⚠️ มีคนแพ้อาหาร · ข้อมูลเป็นค่าทั่วไป ถามร้านทุกครั้ง")
        }
        if store.health.fitRemainingCalories {
            let left = max(store.remainingCalories, 0)
            lines.append(left > 0 ? "🔥 สุ่มเฉพาะเมนูไม่เกิน \(left.formatted()) kcal (ที่เหลือวันนี้)" : "🔥 วันนี้ครบเป้าแคลแล้ว")
        }
        if let day = store.jayDay {
            lines.append("🟡 เทศกาลกินเจ วันที่ \(day)/9" + (store.filter.vegetarian ? " · มังสวิรัติอยู่" : ""))
        }
        return lines
    }

    private var statusBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(statusLines, id: \.self) { line in
                Text(line)
                    .font(.subheadline.weight(.medium))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular.tint(Color.pastelMint.opacity(0.35)), in: .rect(cornerRadius: 18))
    }

    private func chipLabel(_ tag: String) -> String {
        if tag == "ที่ชอบ" { return "❤️ ที่ชอบ" }
        if let group = foodGroups.first(where: { $0.name == tag }) {
            return "\(group.emoji) \(group.name)"
        }
        return tag
    }

    private func subBar(_ group: FoodGroup) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                subChip("ทั้งกลุ่ม", isOn: selectedSub == nil) { selectedSub = nil }
                ForEach(group.categories, id: \.self) { cat in
                    subChip(cat, isOn: selectedSub == cat) { selectedSub = cat }
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func subChip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.snappy) { action() }
        } label: {
            Text(title)
                .font(.subheadline.weight(isOn ? .bold : .regular))
        }
        .buttonStyle(.glass)
        .controlSize(.small)
        .tint(isOn ? Color.pastelMint : nil)
    }

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
                        Text(mode.placeholder)
                            .font(.system(size: 110))
                        Text(emptyMessage)
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(height: 200)
            .clipped()

            if pool.isEmpty && store.filter.isActive {
                Button("ล้างตัวกรอง", systemImage: "xmark.circle") {
                    withAnimation(.snappy) { store.filter = FoodFilter() }
                }
                .buttonStyle(.glass)
            }

            if let food = current, !isSpinning {
                HStack(spacing: 10) {
                    Text("\(food.tag) · \(food.price.label)")
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

                    ShareLink(item: shareText(food)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(.glass)

                    Button {
                        nearbyFood = food
                    } label: {
                        Label("หาร้านใกล้ฉัน", systemImage: "location.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.glass)
                }
                .transition(.scale.combined(with: .opacity))

                Text(foodDetail(food))
                    .font(.caption)
                    .foregroundStyle(Color.ink.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                eatButton(food)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .glassEffect(.regular, in: .rect(cornerRadius: 36))
    }

    private var emptyMessage: String {
        if !pool.isEmpty { return "กดปุ่มด้านล่างเพื่อสุ่ม" }
        if store.hasRestrictions { return "ไม่มีเมนูที่ตรงกับเงื่อนไข" }
        return selectedTag == "ที่ชอบ"
            ? "ยังไม่มีเมนูที่ชอบ\nกดหัวใจที่เมนูก่อนนะ"
            : "เมนูในหมวดนี้ถูกซ่อนหมด\nเปิดคืนได้ที่ปุ่มรายการ"
    }

    private var spinButton: some View {
        Button(action: spin) {
            Label(isSpinning ? "กำลังสุ่ม..." : mode.spinLabel, systemImage: "dice.fill")
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
            HStack {
                Text("สุ่มล่าสุด")
                    .font(.headline)
                Spacer()
                Button("ดูทั้งหมด") { showHistory = true }
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 4)

            ForEach(recentHistory) { entry in
                let food = entry.food
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

    private func foodDetail(_ food: Food) -> String {
        var parts: [String] = []
        if let calories = food.calories { parts.append("~\(calories.formatted()) kcal") }
        if !food.ingredients.isEmpty {
            parts.append("มี " + Ingredients.sorted(food.ingredients).map { Ingredients.label($0) }.joined(separator: "  "))
        }
        return parts.joined(separator: " · ")
    }

    private func eatButton(_ food: Food) -> some View {
        let logged = loggedFoodID == food.id
        let slot = MealSlot.current()
        return Button {
            store.logMeal(food, slot: slot)
            withAnimation(.snappy) { loggedFoodID = food.id }
        } label: {
            Label(logged ? "บันทึกใน\(slot.rawValue)แล้ว" : "กินอันนี้ · บันทึกเป็น\(slot.rawValue)",
                  systemImage: logged ? "checkmark.circle.fill" : "fork.knife")
                .font(.subheadline.weight(.semibold))
        }
        .buttonStyle(.glass)
        .disabled(logged)
        .sensoryFeedback(.success, trigger: logged)
    }

    private var todayCaloriesButton: some View {
        let goal = store.health.calorieGoal
        let today = store.todayCalories
        return Button {
            showMealLog = true
        } label: {
            HStack(spacing: 10) {
                Text("🔥")
                VStack(alignment: .leading, spacing: 4) {
                    Text("วันนี้กินไป \(today.formatted()) / \(goal.formatted()) kcal")
                        .font(.subheadline.weight(.semibold))
                    ProgressView(value: min(Double(today) / Double(max(goal, 1)), 1))
                        .tint(today > goal ? .orange : Color.softAqua)
                }
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.ink.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

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
                loggedFoodID = nil
                isSpinning = false
                if let next { store.record(next) }
            }
            landed += 1
        }
    }

    private func shareText(_ food: Food) -> String {
        "วันนี้กิน \(food.emoji) \(food.name) 🎲 สุ่มจากแอป FoodPicker"
    }

    private func toggleFavorite(_ food: Food) {
        favoritesRaw = NameSet.toggle(food.name, in: favoritesRaw)
    }

    private func resetAll() async {
        guard !isSpinning else { return }
        try? await Task.sleep(for: .milliseconds(400))
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            current = nil
            rolling = nil
            recentSince = .now
            selectedTag = "ทั้งหมด"
            selectedSub = nil
        }
        landed += 1
    }
}
