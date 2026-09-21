import Foundation

enum MealSlot: String, Codable, CaseIterable, Identifiable {
    case breakfast = "มื้อเช้า"
    case lunch = "มื้อกลางวัน"
    case dinner = "มื้อเย็น"
    case snack = "ของว่าง"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .breakfast: "🌅"
        case .lunch: "☀️"
        case .dinner: "🌙"
        case .snack: "🍪"
        }
    }

    static func current(at date: Date = .now, calendar: Calendar = .current) -> MealSlot {
        let minutes = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        switch minutes {
        case 5 * 60..<(10 * 60 + 30): return .breakfast
        case (10 * 60 + 30)..<(15 * 60): return .lunch
        case (17 * 60)..<(21 * 60 + 30): return .dinner
        default: return .snack
        }
    }
}

struct DayCalories: Identifiable {
    let date: Date
    let calories: Int

    var id: Date { date }
}

struct MealEntry: Identifiable, Codable {
    var id = UUID()
    let food: Food
    var slot: MealSlot
    let date: Date

    var calories: Int { food.calories ?? 0 }
}
