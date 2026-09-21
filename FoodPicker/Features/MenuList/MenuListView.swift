import SwiftUI

struct MenuListView: View {
    let mode: MealMode
    @Environment(MenuStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @AppStorage("favorites") private var favoritesRaw = ""
    @AppStorage("excluded") private var excludedRaw = ""
    @State private var search = ""
    @State private var expanded: Set<String> = []
    @State private var showAddMenu = false

    private var favorites: Set<String> { NameSet.decode(favoritesRaw) }
    private var excluded: Set<String> { NameSet.decode(excludedRaw) }

    private var modeCount: Int { store.allFoods.filter { mode.contains($0) }.count }

    private var canCollapse: Bool { search.isEmpty && mode.categories.count > 1 }
    private var allExpanded: Bool { expanded.isSuperset(of: mode.categories) }

    private func isExpanded(_ category: String) -> Binding<Bool> {
        Binding(
            get: { expanded.contains(category) },
            set: { open in
                if open { expanded.insert(category) } else { expanded.remove(category) }
            }
        )
    }

    private func foods(in category: String) -> [Food] {
        store.allFoods.filter {
            $0.tag == category && (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if search.isEmpty {
                    Section {
                        Button {
                            showAddMenu = true
                        } label: {
                            Label("เพิ่มเมนูของฉัน", systemImage: "plus.circle.fill")
                                .font(.body.weight(.semibold))
                        }

                        if canCollapse {
                            Button {
                                withAnimation {
                                    expanded = allExpanded ? [] : Set(mode.categories)
                                }
                            } label: {
                                Label(allExpanded ? "พับทุกหมวด" : "กางทุกหมวด",
                                      systemImage: allExpanded ? "chevron.up.2" : "chevron.down.2")
                            }
                        }
                    } footer: {
                        Text("แตะ ♡ เก็บเป็นเมนูโปรด · แตะ 👁 ซ่อนจากการสุ่ม"
                             + (canCollapse ? " · แตะชื่อหมวดเพื่อกาง/พับ" : "")
                             + " · เมนูที่เพิ่มเอง ปัดซ้ายเพื่อลบ")
                    }
                }

                ForEach(mode.categories, id: \.self) { category in
                    let items = foods(in: category)
                    if !items.isEmpty {
                        if canCollapse {
                            Section("\(category) (\(items.count))", isExpanded: isExpanded(category)) {
                                ForEach(items) { row($0) }
                            }
                        } else {
                            Section("\(category) (\(items.count))") {
                                ForEach(items) { row($0) }
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .searchable(text: $search, prompt: "ค้นหาเมนู")
            .navigationTitle("\(mode.emoji) \(mode.rawValue) \(modeCount) รายการ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !excludedRaw.isEmpty {
                        Button("เปิดคืนทั้งหมด") { excludedRaw = "" }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("เสร็จ") { dismiss() }
                }
            }
            .sheet(isPresented: $showAddMenu) { AddMenuView(mode: mode).environment(store) }
        }
        .tint(Color.ink)
    }

    private func row(_ food: Food) -> some View {
        let isHidden = excluded.contains(food.name)
        let isFavorite = favorites.contains(food.name)

        return HStack(spacing: 12) {
            Text(food.emoji)
                .font(.title2)
                .opacity(isHidden ? 0.35 : 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name)
                    .strikethrough(isHidden)
                    .foregroundStyle(isHidden ? Color.ink.opacity(0.35) : Color.ink)
                let detail = [food.calories.map { "~\($0) kcal" }, food.isCustom ? "เพิ่มเอง" : nil].compactMap { $0 }
                if !detail.isEmpty {
                    Text(detail.joined(separator: " · "))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.ink.opacity(0.5))
                }
            }
            Spacer()
            Button {
                favoritesRaw = NameSet.toggle(food.name, in: favoritesRaw)
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(.pink)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(isFavorite ? "เอาออกจากเมนูโปรด" : "เพิ่มเป็นเมนูโปรด")

            Button {
                excludedRaw = NameSet.toggle(food.name, in: excludedRaw)
            } label: {
                Image(systemName: isHidden ? "eye.slash" : "eye")
                    .foregroundStyle(Color.ink.opacity(0.6))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(isHidden ? "ให้สุ่มเมนูนี้" : "ซ่อนจากการสุ่ม")
        }
        .swipeActions {
            if food.isCustom {
                Button("ลบ", systemImage: "trash", role: .destructive) {
                    store.deleteCustomFood(named: food.name)
                }
            }
        }
    }
}
