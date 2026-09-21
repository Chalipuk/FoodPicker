import Foundation

struct Diner: Identifiable, Equatable {
    var id = UUID()
    var name = ""
    var vegetarian = false
    var noSpicy = false
    var avoid: Set<String> = []
    var allergies: Set<String> = []

    var filter: FoodFilter {
        FoodFilter(spicy: noSpicy ? .mild : .any, vegetarian: vegetarian, avoid: avoid, allergies: allergies)
    }
}

extension Diner: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, name, vegetarian, noSpicy, avoid, allergies
        case noPork, noBeef
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        vegetarian = try c.decodeIfPresent(Bool.self, forKey: .vegetarian) ?? false
        noSpicy = try c.decodeIfPresent(Bool.self, forKey: .noSpicy) ?? false
        avoid = try c.decodeIfPresent(Set<String>.self, forKey: .avoid) ?? []
        allergies = try c.decodeIfPresent(Set<String>.self, forKey: .allergies) ?? []
        if try c.decodeIfPresent(Bool.self, forKey: .noPork) == true { avoid.insert("หมู") }
        if try c.decodeIfPresent(Bool.self, forKey: .noBeef) == true { avoid.insert("เนื้อ") }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(vegetarian, forKey: .vegetarian)
        try c.encode(noSpicy, forKey: .noSpicy)
        try c.encode(avoid, forKey: .avoid)
        try c.encode(allergies, forKey: .allergies)
    }
}

struct DinerGroup: Identifiable, Codable, Equatable {
    var id = UUID()
    var name = ""
    var members: [Diner] = []

    var filter: FoodFilter {
        members.reduce(FoodFilter()) { $0.merged(with: $1.filter) }
    }
}
