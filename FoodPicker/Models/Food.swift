import Foundation

enum PriceLevel: Int, Codable, CaseIterable, Identifiable, Comparable {
    case cheap = 1, mid, high

    var id: Int { rawValue }
    var label: String { String(repeating: "฿", count: rawValue) }

    var hint: String {
        switch self {
        case .cheap: "ไม่เกิน ~100"
        case .mid: "~100–300"
        case .high: "300 ขึ้นไป"
        }
    }

    static func < (a: PriceLevel, b: PriceLevel) -> Bool { a.rawValue < b.rawValue }
}

struct Food: Identifiable, Equatable, Codable {
    let name: String
    let emoji: String
    let tag: String
    let ingredients: Set<String>
    let price: PriceLevel
    let spicy: Bool
    let calories: Int?
    var isCustom = false

    // ชื่อเมนูห้ามซ้ำ จึงใช้ชื่อเป็น id ได้เลย
    var id: String { name }
    var isVegetarian: Bool { ingredients.isDisjoint(with: Ingredients.animalNames) }

    init(_ name: String, _ emoji: String, _ tag: String,
         _ ingredients: Set<String> = [], _ price: PriceLevel = .cheap, spicy: Bool = false, kcal: Int? = nil) {
        self.name = name
        self.emoji = emoji
        self.tag = tag
        self.ingredients = ingredients
        self.price = price
        self.spicy = spicy
        self.calories = kcal
    }
}

extension Food {
    private enum CodingKeys: String, CodingKey {
        case name, emoji, tag, ingredients, price, spicy, calories, isCustom
        case meats
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        emoji = try c.decode(String.self, forKey: .emoji)
        tag = try c.decode(String.self, forKey: .tag)
        price = try c.decode(PriceLevel.self, forKey: .price)
        spicy = try c.decode(Bool.self, forKey: .spicy)
        calories = try c.decodeIfPresent(Int.self, forKey: .calories)
        isCustom = try c.decodeIfPresent(Bool.self, forKey: .isCustom) ?? false
        if let ingredients = try c.decodeIfPresent(Set<String>.self, forKey: .ingredients) {
            self.ingredients = ingredients
        } else {
            let legacy = try c.decodeIfPresent([String].self, forKey: .meats) ?? []
            ingredients = Self.ingredients(fromLegacyMeats: legacy)
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(emoji, forKey: .emoji)
        try c.encode(tag, forKey: .tag)
        try c.encode(ingredients, forKey: .ingredients)
        try c.encode(price, forKey: .price)
        try c.encode(spicy, forKey: .spicy)
        try c.encodeIfPresent(calories, forKey: .calories)
        try c.encode(isCustom, forKey: .isCustom)
    }

    // ข้อมูลรุ่นก่อนเก็บแค่ "meats" 4 แบบ — แปลงแบบเผื่อไว้ก่อน (seafood = ทะเลทุกอย่าง) เพื่อความปลอดภัยของคนแพ้
    private static func ingredients(fromLegacyMeats meats: [String]) -> Set<String> {
        var result = Set<String>()
        for meat in meats {
            switch meat {
            case "pork": result.insert("หมู")
            case "beef": result.insert("เนื้อ")
            case "chicken": result.formUnion(["ไก่", "เป็ด"])
            case "seafood": result.formUnion(Ingredients.names(in: .seafood))
            default: break
            }
        }
        return result
    }
}
