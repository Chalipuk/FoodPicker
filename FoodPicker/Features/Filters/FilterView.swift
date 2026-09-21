import SwiftUI

struct FilterView: View {
    let mode: MealMode
    @Environment(MenuStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            Form {
                Section {
                    Picker("งบไม่เกิน", selection: $store.filter.maxPrice) {
                        Text("ไม่จำกัด").tag(PriceLevel?.none)
                        ForEach(PriceLevel.allCases) { level in
                            Text(level.label).tag(PriceLevel?.some(level))
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("ราคา")
                } footer: {
                    Text(PriceLevel.allCases.map { "\($0.label) \($0.hint)" }.joined(separator: " · "))
                }

                Section {
                    Picker("แคลอรี่ไม่เกิน", selection: $store.filter.maxCalories) {
                        Text("ไม่จำกัด").tag(Int?.none)
                        ForEach([300, 500, 700], id: \.self) { limit in
                            Text("≤\(limit)").tag(Int?.some(limit))
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("🔥 แคลอรี่ต่อจาน")
                } footer: {
                    Text("ค่าโดยประมาณ · ต้ม/แกงยังไม่รวมข้าว (ข้าวสวย ~250 kcal)")
                }

                if mode == .food {
                    Section("ความเผ็ด") {
                        Picker("ความเผ็ด", selection: $store.filter.spicy) {
                            ForEach(SpicyFilter.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section {
                        Toggle("🥦 มังสวิรัติ", isOn: $store.filter.vegetarian)
                    }
                }

                Section {
                    IngredientSelectionRow(
                        title: "🚫 ไม่กิน / ไม่ชอบ",
                        footer: "เมนูที่มีวัตถุดิบเหล่านี้จะไม่ถูกสุ่ม เช่น ไม่กินหมูตามศาสนา หรือไม่ชอบผักชี",
                        selection: $store.filter.avoid,
                        suggestions: store.customIngredientNames)
                    IngredientSelectionRow(
                        title: "⚠️ แพ้อาหาร",
                        footer: "⚠️ ข้อมูลวัตถุดิบเป็นค่าโดยทั่วไป แต่ละร้านอาจต่างกัน และอาจมีวัตถุดิบแฝง เช่น น้ำปลา ซอสหอยนางรม — คนแพ้รุนแรงต้องถามร้านทุกครั้ง",
                        selection: $store.filter.allergies,
                        suggestions: store.customIngredientNames,
                        tint: Color.orange.opacity(0.35))
                } header: {
                    Text("วัตถุดิบ")
                } footer: {
                    Text("ใช้ได้ทุกโหมด เช่น แพ้นม จะกรองเครื่องดื่มที่มีนมด้วย")
                }

                Section {
                    Toggle("💸 โหมดปลายเดือน", isOn: $store.settings.budgetModeEnabled)
                    if store.settings.budgetModeEnabled {
                        Stepper("เงินเดือนออกวันที่ \(store.settings.payday)",
                                value: $store.settings.payday, in: 1...31)
                        Stepper("เริ่มประหยัดก่อน \(store.settings.budgetDaysBefore) วัน",
                                value: $store.settings.budgetDaysBefore, in: 1...15)
                    }
                } header: {
                    Text("โหมดอัตโนมัติ")
                } footer: {
                    Text(budgetFooter)
                }

                Section {
                    Toggle("🟡 ถามเมื่อถึงเทศกาลกินเจ", isOn: $store.settings.askDuringJay)
                } footer: {
                    Text(jayFooter)
                }
            }
            .navigationTitle("ตัวกรอง")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if store.filter.isActive {
                        Button("ล้าง") { store.filter = FoodFilter() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("เสร็จ") { dismiss() }
                }
            }
        }
        .tint(Color.ink)
        .presentationDetents([.medium, .large])
    }

    private var budgetFooter: String {
        guard let days = store.budgetDaysLeft else {
            return "ช่วงใกล้เงินเดือนออก จะสุ่มเฉพาะเมนูราคา ฿ ให้อัตโนมัติ"
        }
        let status = days == 0 ? "เงินเดือนออกวันนี้" : "อีก \(days) วันเงินเดือนออก"
        return "\(status) · \(store.isBudgetTight ? "ตอนนี้สุ่มเฉพาะ ฿" : "ตอนนี้สุ่มได้ทุกราคา")"
    }

    private var jayFooter: String {
        let note = "เปิดตัวกรองมังสวิรัติให้ และปิดให้เองเมื่อหมดเทศกาล (ไม่ใช่อาหารเจแบบเคร่ง)"
        guard let festival = CalendarRules.nextJayFestival() else { return note }
        let style = Date.FormatStyle().day().month(.abbreviated).locale(Locale(identifier: "th_TH"))
        let range = "\(festival.lowerBound.formatted(style)) – \(festival.upperBound.formatted(style))"
        return (store.jayDay != nil ? "ตอนนี้ช่วงกินเจ ถึง \(festival.upperBound.formatted(style))" : "กินเจรอบถัดไป \(range)") + " · " + note
    }
}
