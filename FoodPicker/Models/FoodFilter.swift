import Foundation

enum SpicyFilter: String, Codable, CaseIterable, Identifiable {
    case any = "ทั้งหมด"
    case spicy = "เผ็ด"
    case mild = "ไม่เผ็ด"

    var id: String { rawValue }
}

struct FoodFilter: Equatable {
    var spicy: SpicyFilter = .any
    var vegetarian = false
    var avoid: Set<String> = []
    var allergies: Set<String> = []
    var maxPrice: PriceLevel?
    var maxCalories: Int?
    var isActive: Bool { activeCount > 0 }
    var activeCount: Int {
        [spicy != .any, vegetarian, !avoid.isEmpty, !allergies.isEmpty, maxPrice != nil, maxCalories != nil].filter { $0 }.count
    }

    var dietLabels: [String] {
        var labels: [String] = []
        if vegetarian { labels.append("🥦 มังสวิรัติ") }
        if !avoid.isEmpty { labels.append("🚫 ไม่กิน \(Ingredients.list(avoid))") }
        if !allergies.isEmpty { labels.append("⚠️ แพ้ \(Ingredients.list(allergies))") }
        if spicy == .mild { labels.append("🌶️ ไม่เผ็ด") }
        return labels
    }

    // รวมสองตัวกรองโดยเอาข้อที่เข้มกว่า — ถ้าฝั่งไหนขอ "ไม่เผ็ด" ต้องไม่เผ็ด
    func merged(with other: FoodFilter) -> FoodFilter {
        var result = self
        result.vegetarian = vegetarian || other.vegetarian
        result.avoid = avoid.union(other.avoid)
        result.allergies = allergies.union(other.allergies)
        if spicy == .mild || other.spicy == .mild {
            result.spicy = .mild
        } else if other.spicy == .spicy {
            result.spicy = .spicy
        }
        result.maxPrice = [maxPrice, other.maxPrice].compactMap { $0 }.min()
        result.maxCalories = [maxCalories, other.maxCalories].compactMap { $0 }.min()
        return result
    }

    // ราคา / ไม่กิน / แพ้ ใช้ทุกโหมด (เช่น แพ้นม ต้องกรองเครื่องดื่มด้วย) ส่วนความเผ็ดและมังสวิรัติใช้กับอาหารเท่านั้น
    func allows(_ food: Food, in mode: MealMode) -> Bool {
        if let maxPrice, food.price > maxPrice { return false }
        if let maxCalories, let calories = food.calories, calories > maxCalories { return false }
        if !food.ingredients.isDisjoint(with: allergies) { return false }
        if !food.ingredients.isDisjoint(with: avoid) { return false }
        guard mode == .food else { return true }

        switch spicy {
            case .any: break
            case .spicy: if !food.spicy { return false }
            case .mild: if food.spicy { return false }
        }
        if vegetarian && !food.isVegetarian { return false }
        return true
    }
}

extension FoodFilter: Codable {
    private enum CodingKeys: String, CodingKey {
        case spicy, vegetarian, avoid, allergies, maxPrice, maxCalories
        case noPork, noBeef
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        spicy = try c.decodeIfPresent(SpicyFilter.self, forKey: .spicy) ?? .any
        vegetarian = try c.decodeIfPresent(Bool.self, forKey: .vegetarian) ?? false
        avoid = try c.decodeIfPresent(Set<String>.self, forKey: .avoid) ?? []
        allergies = try c.decodeIfPresent(Set<String>.self, forKey: .allergies) ?? []
        maxPrice = try c.decodeIfPresent(PriceLevel.self, forKey: .maxPrice)
        maxCalories = try c.decodeIfPresent(Int.self, forKey: .maxCalories)
        if try c.decodeIfPresent(Bool.self, forKey: .noPork) == true { avoid.insert("หมู") }
        if try c.decodeIfPresent(Bool.self, forKey: .noBeef) == true { avoid.insert("เนื้อ") }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(spicy, forKey: .spicy)
        try c.encode(vegetarian, forKey: .vegetarian)
        try c.encode(avoid, forKey: .avoid)
        try c.encode(allergies, forKey: .allergies)
        try c.encodeIfPresent(maxPrice, forKey: .maxPrice)
        try c.encodeIfPresent(maxCalories, forKey: .maxCalories)
    }
}
