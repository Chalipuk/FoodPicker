import SwiftUI

struct GroupEditView: View {
    @Environment(MenuStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: DinerGroup

    init(group: DinerGroup) {
        _draft = State(initialValue: group)
    }

    private var trimmedName: String { draft.name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty && !draft.members.isEmpty }

    private var edibleCount: Int {
        store.allFoods.filter { MealMode.food.contains($0) && draft.filter.allows($0, in: .food) }.count
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("ชื่อกลุ่ม เช่น ทีม Dev, แก๊งเที่ยง", text: $draft.name)
                }

                Section {
                    ForEach($draft.members) { $member in
                        NavigationLink {
                            DinerEditView(diner: $member)
                        } label: {
                            memberRow(member)
                        }
                    }
                    .onDelete { draft.members.remove(atOffsets: $0) }

                    Button("เพิ่มคน (กรอกเอง)", systemImage: "person.badge.plus") {
                        draft.members.append(Diner(name: "คนที่ \(draft.members.count + 1)"))
                    }
                    if !store.profile.name.isEmpty && !draft.members.contains(where: { $0.id == store.profile.id }) {
                        Button("เพิ่มฉัน (\(store.profile.name))", systemImage: "person.crop.circle.badge.plus") {
                            upsert(store.myProfile)
                        }
                    }
                    PasteButton(payloadType: String.self) { texts in
                        Task { @MainActor in
                            let diner = texts.lazy.compactMap { ProfileLink.diner(fromText: $0) }.first
                            if let diner { upsert(diner) }
                        }
                    }
                } header: {
                    Text("สมาชิก \(draft.members.count) คน")
                } footer: {
                    Text("แตะชื่อเพื่อตั้งข้อจำกัด · ปัดซ้ายเพื่อลบ · \"วาง\" = เพิ่มจากโปรไฟล์ที่เพื่อนส่งมา")
                }

                Section("ทั้งกลุ่ม") {
                    let labels = draft.filter.dietLabels
                    Text(labels.isEmpty ? "✅ ทุกคนกินได้ทุกอย่าง" : labels.joined(separator: "  "))
                    Text("มี \(edibleCount) เมนูที่ทุกคนกินได้")
                        .foregroundStyle(edibleCount == 0 ? .red : Color.ink.opacity(0.7))
                }
            }
            .navigationTitle(store.groups.contains { $0.id == draft.id } ? "แก้ไขกลุ่ม" : "กลุ่มใหม่")
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

    private func memberRow(_ member: Diner) -> some View {
        let labels = member.filter.dietLabels
        return VStack(alignment: .leading, spacing: 2) {
            Text(member.name.isEmpty ? "ไม่มีชื่อ" : member.name)
            Text(labels.isEmpty ? "กินได้ทุกอย่าง" : labels.joined(separator: " "))
                .font(.caption)
                .foregroundStyle(Color.ink.opacity(0.6))
        }
    }

    private func upsert(_ diner: Diner) {
        if let index = draft.members.firstIndex(where: { $0.id == diner.id }) {
            draft.members[index] = diner
        } else {
            draft.members.append(diner)
        }
    }

    private func save() {
        var group = draft
        group.name = trimmedName
        store.saveGroup(group)
        dismiss()
    }
}

struct DinerEditView: View {
    @Environment(MenuStore.self) private var store
    @Binding var diner: Diner

    var body: some View {
        Form {
            Section {
                TextField("ชื่อ", text: $diner.name)
            }

            Section("การกิน") {
                Toggle("🥦 มังสวิรัติ", isOn: $diner.vegetarian)
                Toggle("🌶️ กินเผ็ดไม่ได้", isOn: $diner.noSpicy)
            }

            Section {
                IngredientSelectionRow(
                    title: "🚫 ไม่กิน / ไม่ชอบ",
                    footer: "เช่น ไม่กินหมูตามศาสนา ไม่กินเนื้อ หรือไม่ชอบผักชี",
                    selection: $diner.avoid,
                    suggestions: store.customIngredientNames)
                IngredientSelectionRow(
                    title: "⚠️ แพ้อาหาร",
                    footer: "⚠️ ข้อมูลวัตถุดิบเป็นค่าโดยทั่วไป อาจมีวัตถุดิบแฝง เช่น น้ำปลา ซอสหอยนางรม — คนแพ้รุนแรงต้องถามร้านทุกครั้ง",
                    selection: $diner.allergies,
                    suggestions: store.customIngredientNames,
                    tint: Color.orange.opacity(0.35))
            } header: {
                Text("วัตถุดิบ")
            }
        }
        .navigationTitle(diner.name.isEmpty ? "สมาชิก" : diner.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
