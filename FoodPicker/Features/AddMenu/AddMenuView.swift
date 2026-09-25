import SwiftUI

struct AddMenuView: View {
    @Environment(MenuStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = ""
    @State private var category: String
    @State private var ingredients: Set<String> = []
    @State private var price: PriceLevel = .cheap
    @State private var spicy = false
    @State private var calories: Int?

    init(mode: MealMode) {
        _category = State(initialValue: mode.categories.first ?? foodCategories[0])
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isDuplicate: Bool { store.isNameTaken(trimmedName) }
    private var canSave: Bool { !trimmedName.isEmpty && !isDuplicate }
    // ของหวาน/เครื่องดื่ม ไม่ต้องกรอกเนื้อสัตว์และความเผ็ด
    private var isSavory: Bool { MealMode.food.categories.contains(category) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("ชื่อเมนู เช่น ข้าวมันไก่ป้าแดง", text: $name)
                    TextField("อีโมจิ (ไม่ใส่ก็ได้)", text: $emoji)
                        .onChange(of: emoji) {
                            if emoji.count > 1 { emoji = String(emoji.prefix(1)) }
                        }
                } footer: {
                    if isDuplicate {
                        Text("มีเมนูชื่อนี้อยู่แล้ว").foregroundStyle(.red)
                    }
                }

                Section {
                    Picker("หมวด", selection: $category) {
                        ForEach(foodCategories, id: \.self) { Text($0) }
                    }
                    Picker("ราคา", selection: $price) {
                        ForEach(PriceLevel.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    HStack {
                        Text("🔥 แคลอรี่")
                        TextField("ไม่ใส่ก็ได้", value: $calories, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("kcal").foregroundStyle(Color.ink.opacity(0.6))
                    }
                }

                if isSavory {
                    Section {
                        Toggle("🌶️ เผ็ด", isOn: $spicy)
                    }
                }

                Section {
                    Text("แตะเลือกวัตถุดิบที่อยู่ในเมนูนี้ เพื่อให้ตัวกรอง \"ไม่กิน\" และ \"แพ้\" รู้จักเมนูนี้ด้วย · ถ้าไม่เลือกเนื้อสัตว์และอาหารทะเลเลย จะนับเป็นมังสวิรัติ")
                        .font(.footnote)
                        .foregroundStyle(Color.ink.opacity(0.7))
                } header: {
                    Text("มีอะไรอยู่ในเมนูนี้")
                }
                IngredientPicker(selection: $ingredients, suggestions: store.customIngredientNames)
            }
            .navigationTitle("เพิ่มเมนูเอง")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("ยกเลิก") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("บันทึก", action: save)
                        .fontWeight(.bold)
                        .disabled(!canSave)
                }
            }
        }
        .tint(Color.ink)
    }

    private func save() {
        store.addCustomFood(Food(
            trimmedName,
            emoji.isEmpty ? "🍽️" : emoji,
            category,
            ingredients,
            price,
            spicy: isSavory && spicy,
            kcal: calories
        ))
        dismiss()
    }
}
