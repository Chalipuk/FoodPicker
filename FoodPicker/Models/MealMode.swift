import Foundation

enum MealMode: String, CaseIterable, Identifiable {
    case food = "อาหาร"
    case dessert = "ของหวาน"
    case drink = "เครื่องดื่ม"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .food: "🍛"
        case .dessert: "🍰"
        case .drink: "🧋"
        }
    }

    var question: String {
        switch self {
        case .food: "วันนี้กินอะไรดี?"
        case .dessert: "ของหวานอะไรดี?"
        case .drink: "ดื่มอะไรดี?"
        }
    }

    var spinLabel: String {
        switch self {
        case .food: "สุ่มเมนู"
        case .dessert: "สุ่มของหวาน"
        case .drink: "สุ่มเครื่องดื่ม"
        }
    }

    var placeholder: String {
        switch self {
        case .food: "🍽️"
        case .dessert: "🍨"
        case .drink: "🥤"
        }
    }

    var categories: [String] {
        switch self {
        case .dessert: ["ของหวาน"]
        case .drink: ["เครื่องดื่ม"]
        case .food: foodCategories.filter { $0 != "ของหวาน" && $0 != "เครื่องดื่ม" }
        }
    }

    func contains(_ food: Food) -> Bool {
        categories.contains(food.tag)
    }
}
