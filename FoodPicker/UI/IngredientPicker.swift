import SwiftUI

// ใส่ใน Form ได้ตรง ๆ — แสดงเป็น Section ละกลุ่ม + ส่วนเพิ่มเอง
struct IngredientPicker: View {
    @Binding var selection: Set<String>
    var suggestions: [String] = []
    var tint: Color = .pastelMint

    @State private var newName = ""

    private var trimmedNew: String { newName.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var customNames: [String] {
        Set(suggestions).union(selection).subtracting(Ingredients.knownNames).sorted()
    }

    var body: some View {
        ForEach(IngredientGroup.allCases) { group in
            let names = Ingredients.names(in: group)
            let allOn = selection.isSuperset(of: names)
            Section {
                FlowLayout {
                    ForEach(names, id: \.self) { chip($0) }
                }
                .padding(.vertical, 4)
            } header: {
                HStack {
                    Text(group.rawValue)
                    Spacer()
                    Button(allOn ? "ไม่เลือกทั้งกลุ่ม" : "เลือกทั้งกลุ่ม") {
                        if allOn { selection.subtract(names) } else { selection.formUnion(names) }
                    }
                    .font(.caption.weight(.semibold))
                    .textCase(nil)
                }
            }
        }

        Section("➕ เพิ่มเอง") {
            if !customNames.isEmpty {
                FlowLayout {
                    ForEach(customNames, id: \.self) { chip($0) }
                }
                .padding(.vertical, 4)
            }
            HStack {
                TextField("เช่น ผักชี, เห็ด, มะเขือ", text: $newName)
                    .onSubmit(addNew)
                Button("เพิ่ม", action: addNew)
                    .buttonStyle(.borderless)
                    .disabled(trimmedNew.isEmpty)
            }
        }
    }

    private func chip(_ name: String) -> some View {
        let isOn = selection.contains(name)
        return Button {
            if isOn { selection.remove(name) } else { selection.insert(name) }
        } label: {
            Text(Ingredients.label(name))
                .font(.subheadline.weight(isOn ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(isOn ? tint : Color.ink.opacity(0.07)))
                .overlay(Capsule().strokeBorder(isOn ? Color.ink.opacity(0.35) : .clear))
                .foregroundStyle(Color.ink)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func addNew() {
        guard !trimmedNew.isEmpty else { return }
        selection.insert(trimmedNew)
        newName = ""
    }
}

// แถวสรุปใน Form ที่แตะแล้วไปหน้าเลือกวัตถุดิบ
struct IngredientSelectionRow: View {
    let title: String
    let footer: String
    @Binding var selection: Set<String>
    var suggestions: [String] = []
    var tint: Color = .pastelMint

    var body: some View {
        NavigationLink {
            Form {
                Section {
                    Text(footer)
                        .font(.footnote)
                        .foregroundStyle(Color.ink.opacity(0.7))
                }
                IngredientPicker(selection: $selection, suggestions: suggestions, tint: tint)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(selection.isEmpty ? "ไม่มี" : Ingredients.list(selection))
                    .font(.caption)
                    .foregroundStyle(Color.ink.opacity(0.6))
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, usedWidth: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            usedWidth = max(usedWidth, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: min(usedWidth, maxWidth), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
