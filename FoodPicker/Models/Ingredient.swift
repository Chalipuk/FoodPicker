import Foundation

enum IngredientGroup: String, CaseIterable, Identifiable {
    case meat = "🥩 เนื้อสัตว์"
    case seafood = "🦐 อาหารทะเล"
    case allergen = "⚠️ แพ้บ่อย"

    var id: String { rawValue }
}

struct IngredientInfo {
    let name: String
    let emoji: String
    let group: IngredientGroup
}

// วัตถุดิบเก็บเป็นชื่อภาษาไทย (String) — ผู้ใช้จึงเพิ่มชื่อใหม่เองได้ เช่น "ผักชี"
enum Ingredients {
    static let all: [IngredientInfo] = [
        IngredientInfo(name: "หมู", emoji: "🐷", group: .meat),
        IngredientInfo(name: "เนื้อ", emoji: "🐮", group: .meat),
        IngredientInfo(name: "ไก่", emoji: "🐔", group: .meat),
        IngredientInfo(name: "เป็ด", emoji: "🦆", group: .meat),

        IngredientInfo(name: "ปลา", emoji: "🐟", group: .seafood),
        IngredientInfo(name: "กุ้ง", emoji: "🦐", group: .seafood),
        IngredientInfo(name: "ปู", emoji: "🦀", group: .seafood),
        IngredientInfo(name: "หอย", emoji: "🦪", group: .seafood),
        IngredientInfo(name: "ปลาหมึก", emoji: "🦑", group: .seafood),
        IngredientInfo(name: "แมงดา", emoji: "🌊", group: .seafood),

        IngredientInfo(name: "ไข่", emoji: "🥚", group: .allergen),
        IngredientInfo(name: "นม", emoji: "🥛", group: .allergen),
        IngredientInfo(name: "ถั่วลิสง", emoji: "🥜", group: .allergen),
        IngredientInfo(name: "ถั่วเหลือง", emoji: "🫘", group: .allergen),
        IngredientInfo(name: "แป้งสาลี", emoji: "🌾", group: .allergen),
        IngredientInfo(name: "งา", emoji: "⚪️", group: .allergen),
    ]

    static let knownNames = Set(all.map(\.name))
    static let animalNames = Set(all.filter { $0.group != .allergen }.map(\.name))

    static func names(in group: IngredientGroup) -> [String] {
        all.filter { $0.group == group }.map(\.name)
    }

    static func label(_ name: String) -> String {
        let emoji = all.first { $0.name == name }?.emoji ?? "🏷️"
        return "\(emoji) \(name)"
    }

    static func sorted(_ names: Set<String>) -> [String] {
        let order = Dictionary(uniqueKeysWithValues: all.enumerated().map { ($1.name, $0) })
        return names.sorted { (order[$0] ?? .max, $0) < (order[$1] ?? .max, $1) }
    }

    static func list(_ names: Set<String>) -> String {
        sorted(names).joined(separator: ", ")
    }
}
