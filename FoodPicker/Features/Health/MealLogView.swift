import SwiftUI

struct MealLogView: View {
    @Environment(MenuStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var addingTo: MealSlot?

    private static let dayStyle = Date.FormatStyle()
        .weekday(.abbreviated).day().month(.abbreviated)
        .locale(Locale(identifier: "th_TH"))
    private static let timeStyle = Date.FormatStyle().hour().minute()
        .locale(Locale(identifier: "th_TH"))

    var body: some View {
        @Bindable var store = store
        let goal = store.health.calorieGoal
        let remaining = store.remainingCalories

        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(store.todayCalories.formatted())
                                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                            Text("/ \(goal.formatted()) kcal")
                                .foregroundStyle(Color.ink.opacity(0.6))
                        }
                        ProgressView(value: min(Double(store.todayCalories) / Double(max(goal, 1)), 1))
                            .tint(remaining < 0 ? .orange : Color.softAqua)
                        Text(remaining >= 0 ? "เหลืออีก \(remaining.formatted()) kcal" : "เกินเป้า \((-remaining).formatted()) kcal")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(remaining < 0 ? .orange : Color.ink)
                    }
                    .padding(.vertical, 6)
                } footer: {
                    Text("แคลอรี่เป็นค่าโดยประมาณ แต่ละร้านต่างกัน · ไม่ใช่คำแนะนำทางการแพทย์")
                }

                ForEach(MealSlot.allCases) { slot in
                    let entries = store.todayMeals.filter { $0.slot == slot }
                    let total = entries.reduce(0) { $0 + $1.calories }
                    Section {
                        ForEach(entries) { entry in
                            row(entry)
                        }
                        .onDelete { offsets in
                            offsets.map { entries[$0] }.forEach(store.deleteMeal)
                        }

                        Button("เพิ่ม", systemImage: "plus") { addingTo = slot }
                    } header: {
                        HStack {
                            Text("\(slot.emoji) \(slot.rawValue)")
                            Spacer()
                            if total > 0 { Text("\(total.formatted()) kcal") }
                        }
                    }
                }

                Section("ย้อนหลัง 7 วัน") {
                    ForEach(store.dailyCalories(days: 7)) { day in
                        HStack {
                            Text(day.date.formatted(Self.dayStyle))
                            Spacer()
                            Text(day.calories == 0 ? "–" : "\(day.calories.formatted()) kcal")
                                .foregroundStyle(day.calories > goal ? .orange : Color.ink.opacity(0.7))
                        }
                    }
                }

                Section {
                    Stepper("เป้าหมาย \(goal.formatted()) kcal/วัน",
                            value: $store.health.calorieGoal, in: 1000...4000, step: 100)
                    Toggle("สุ่มเฉพาะเมนูที่ไม่เกินแคลที่เหลือวันนี้", isOn: $store.health.fitRemainingCalories)
                } header: {
                    Text("ตั้งค่า")
                } footer: {
                    Text("กดค้างที่รายการเพื่อย้ายไปมื้ออื่น · ปัดซ้ายเพื่อลบ")
                }
            }
            .navigationTitle("วันนี้กินไป")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("เสร็จ") { dismiss() }
                }
            }
            .sheet(item: $addingTo) { slot in
                FoodSearchPicker(slot: slot).environment(store)
            }
        }
        .tint(Color.ink)
    }

    private func row(_ entry: MealEntry) -> some View {
        HStack(spacing: 12) {
            Text(entry.food.emoji).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.food.name)
                Text(entry.date.formatted(Self.timeStyle))
                    .font(.caption)
                    .foregroundStyle(Color.ink.opacity(0.6))
            }
            Spacer()
            Text(entry.food.calories.map { "\($0.formatted()) kcal" } ?? "ไม่ระบุ")
                .font(.subheadline)
                .foregroundStyle(Color.ink.opacity(0.7))
        }
        .contextMenu {
            ForEach(MealSlot.allCases.filter { $0 != entry.slot }) { slot in
                Button("ย้ายไป\(slot.rawValue)") { store.moveMeal(entry, to: slot) }
            }
        }
    }
}

struct FoodSearchPicker: View {
    let slot: MealSlot
    @Environment(MenuStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var results: [Food] {
        search.isEmpty ? store.allFoods : store.allFoods.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                if search.isEmpty {
                    Section("ด่วน") { foodRow(.steamedRice) }
                }
                Section {
                    ForEach(results) { foodRow($0) }
                }
            }
            .searchable(text: $search, prompt: "ค้นหาเมนู")
            .navigationTitle("เพิ่มใน\(slot.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("ยกเลิก") { dismiss() }
                }
            }
        }
        .tint(Color.ink)
    }

    private func foodRow(_ food: Food) -> some View {
        Button {
            store.logMeal(food, slot: slot)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Text(food.emoji).font(.title3)
                Text(food.name).foregroundStyle(Color.ink)
                Spacer()
                Text(food.calories.map { "\($0.formatted()) kcal" } ?? "ไม่ระบุ")
                    .font(.subheadline)
                    .foregroundStyle(Color.ink.opacity(0.6))
            }
        }
    }
}
