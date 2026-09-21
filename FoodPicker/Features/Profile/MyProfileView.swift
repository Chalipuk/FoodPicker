import SwiftUI

struct MyProfileView: View {
    @Environment(MenuStore.self) private var store

    private var hasName: Bool { !store.profile.name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        @Bindable var store = store

        Form {
            Section {
                TextField("ชื่อที่เพื่อนจะเห็น", text: $store.profile.name)
            } header: {
                Text("ชื่อ")
            }

            Section("การกิน") {
                Toggle("🥦 มังสวิรัติ", isOn: $store.filter.vegetarian)
                Toggle("🌶️ กินเผ็ดไม่ได้", isOn: Binding(
                    get: { store.filter.spicy == .mild },
                    set: { store.filter.spicy = $0 ? .mild : .any }
                ))
            }

            Section {
                IngredientSelectionRow(
                    title: "🚫 ไม่กิน / ไม่ชอบ",
                    footer: "เช่น ไม่กินหมูตามศาสนา ไม่กินเนื้อ หรือไม่ชอบผักชี",
                    selection: $store.filter.avoid,
                    suggestions: store.customIngredientNames)
                IngredientSelectionRow(
                    title: "⚠️ แพ้อาหาร",
                    footer: "⚠️ ข้อมูลวัตถุดิบเป็นค่าโดยทั่วไป อาจมีวัตถุดิบแฝง — คนแพ้รุนแรงต้องถามร้านทุกครั้ง",
                    selection: $store.filter.allergies,
                    suggestions: store.customIngredientNames,
                    tint: Color.orange.opacity(0.35))
            } header: {
                Text("วัตถุดิบ")
            } footer: {
                Text("ข้อมูลชุดนี้คือตัวกรองส่วนตัวของคุณด้วย แก้ที่ไหนก็เปลี่ยนทั้งสองที่")
            }

            Section {
                if !hasName {
                    Text("ใส่ชื่อก่อน แล้วจะแชร์ได้")
                        .foregroundStyle(Color.ink.opacity(0.6))
                } else if let url = ProfileLink.url(for: store.myProfile) {
                    VStack(spacing: 10) {
                        if let image = ProfileLink.qrImage(for: url) {
                            Image(uiImage: image)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 220)
                                .accessibilityLabel("QR โปรไฟล์ของ \(store.profile.name)")
                        }
                        Text("ให้เพื่อนเปิดกล้องมือถือแล้วสแกน")
                            .font(.footnote)
                            .foregroundStyle(Color.ink.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    ShareLink(item: shareText(url)) {
                        Label("ส่งโปรไฟล์ทาง LINE / แอปอื่น", systemImage: "square.and.arrow.up")
                    }
                }
            } header: {
                Text("แชร์โปรไฟล์")
            } footer: {
                Text("เพื่อนที่ได้รับ: เปิด FoodPicker › กินด้วยกัน › \"วางโปรไฟล์เพื่อน\" · ข้อมูลแพ้อาหารเป็นข้อมูลส่วนตัว แชร์เฉพาะคนที่ไว้ใจ · แก้ข้อมูลแล้วส่งให้เพื่อนใหม่ ข้อมูลในกลุ่มของเพื่อนจะอัปเดต")
            }
        }
        .navigationTitle("โปรไฟล์ของฉัน")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func shareText(_ url: URL) -> String {
        "เพิ่ม \(store.profile.name) เข้ากลุ่มกินข้าวใน FoodPicker 🍽️\nคัดลอกข้อความนี้ แล้วกด \"วางโปรไฟล์เพื่อน\" ในแอป\n\(url.absoluteString)"
    }
}

struct ImportProfileView: View {
    let diner: Diner
    @Environment(MenuStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var newGroupName = ""

    private var displayName: String { diner.name.isEmpty ? "ไม่มีชื่อ" : diner.name }

    var body: some View {
        NavigationStack {
            Form {
                Section("โปรไฟล์ที่ได้รับ") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🙋 \(displayName)").font(.title3.bold())
                        let labels = diner.filter.dietLabels
                        Text(labels.isEmpty ? "กินได้ทุกอย่าง" : labels.joined(separator: "  "))
                            .foregroundStyle(Color.ink.opacity(0.7))
                    }
                    .padding(.vertical, 4)
                }

                if !store.groups.isEmpty {
                    Section("เพิ่มเข้ากลุ่ม") {
                        ForEach(store.groups) { group in
                            let isMember = group.members.contains { $0.id == diner.id }
                            Button {
                                store.add(diner, toGroupID: group.id)
                                dismiss()
                            } label: {
                                HStack {
                                    Text("👥 \(group.name)").foregroundStyle(Color.ink)
                                    Spacer()
                                    Text(isMember ? "อัปเดตข้อมูล" : "เพิ่ม")
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                        }
                    }
                }

                Section("หรือสร้างกลุ่มใหม่") {
                    TextField("ชื่อกลุ่ม เช่น ทีม Dev", text: $newGroupName)
                    Button("สร้างกลุ่มพร้อม \(displayName)") {
                        let name = newGroupName.trimmingCharacters(in: .whitespaces)
                        store.saveGroup(DinerGroup(name: name.isEmpty ? "กินกับ \(displayName)" : name, members: [diner]))
                        dismiss()
                    }
                }
            }
            .navigationTitle("รับโปรไฟล์เพื่อน")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("ยกเลิก") { dismiss() }
                }
            }
        }
        .tint(Color.ink)
    }
}
