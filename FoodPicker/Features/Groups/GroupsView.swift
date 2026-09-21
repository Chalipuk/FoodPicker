import SwiftUI

struct GroupsView: View {
    @Environment(MenuStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var editing: DinerGroup?
    @State private var importing: Diner?
    @State private var pasteFailed = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        MyProfileView()
                    } label: {
                        Label(store.profile.name.isEmpty ? "โปรไฟล์ของฉัน" : "โปรไฟล์ของฉัน · \(store.profile.name)",
                              systemImage: "person.crop.circle")
                    }
                    PasteButton(payloadType: String.self) { texts in
                        Task { @MainActor in
                            let diner = texts.lazy.compactMap { ProfileLink.diner(fromText: $0) }.first
                            if let diner { importing = diner } else { pasteFailed = true }
                        }
                    }
                } header: {
                    Text("แชร์กับเพื่อน")
                } footer: {
                    Text("ตั้งโปรไฟล์แล้วส่ง QR/ลิงก์ให้เพื่อน · ได้ข้อความจากเพื่อน กด \"วาง\" เพื่อเพิ่มเข้ากลุ่ม")
                }

                Section {
                    row(title: "🙋 กินคนเดียว", subtitle: "ใช้แค่ตัวกรองของฉัน", isOn: store.activeGroup == nil) {
                        store.activeGroupID = nil
                    }
                }

                Section {
                    ForEach(store.groups) { group in
                        row(title: "👥 \(group.name)", subtitle: summary(of: group), isOn: store.activeGroupID == group.id) {
                            store.activeGroupID = group.id
                        } edit: {
                            editing = group
                        }
                        .swipeActions {
                            Button("ลบ", systemImage: "trash", role: .destructive) {
                                store.deleteGroup(group)
                            }
                        }
                    }

                    Button("สร้างกลุ่มใหม่", systemImage: "plus") {
                        editing = DinerGroup()
                    }
                } header: {
                    Text("กลุ่ม")
                } footer: {
                    Text("เลือกกลุ่มแล้ว แอปจะสุ่มเฉพาะเมนูที่ทุกคนในกลุ่มกินได้")
                }
            }
            .navigationTitle("กินด้วยกัน")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("เสร็จ") { dismiss() }
                }
            }
            .sheet(item: $editing) { group in
                GroupEditView(group: group).environment(store)
            }
            .sheet(item: $importing) { diner in
                ImportProfileView(diner: diner).environment(store)
            }
            .alert("ไม่พบโปรไฟล์ในข้อความที่วาง", isPresented: $pasteFailed) {
                Button("ตกลง", role: .cancel) {}
            } message: {
                Text("คัดลอกข้อความทั้งหมดที่เพื่อนส่งมา (มีลิงก์ foodpicker://) แล้วลองวางใหม่")
            }
        }
        .tint(Color.ink)
    }

    private func summary(of group: DinerGroup) -> String {
        let labels = group.filter.dietLabels
        let people = "\(group.members.count) คน"
        return labels.isEmpty ? "\(people) · กินได้ทุกอย่าง" : "\(people) · " + labels.joined(separator: " ")
    }

    private func row(title: String, subtitle: String, isOn: Bool,
                     select: @escaping () -> Void, edit: (() -> Void)? = nil) -> some View {
        HStack(spacing: 12) {
            Button {
                select()
                dismiss()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.body.weight(.semibold))
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Color.ink.opacity(0.6))
                    }
                    Spacer()
                    if isOn {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.softAqua)
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            if let edit {
                Button("แก้ไข", systemImage: "pencil", action: edit)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
            }
        }
    }
}
