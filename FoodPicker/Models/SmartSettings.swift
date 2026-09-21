import Foundation

struct SmartSettings: Codable, Equatable {
    var budgetModeEnabled = false
    var payday = 25
    var budgetDaysBefore = 5

    var askDuringJay = true
    var jayAskedYear: Int?
    var jayTurnedOnVegetarian = false
}

struct HealthSettings: Codable, Equatable {
    var calorieGoal = 2000
    var fitRemainingCalories = false
}

struct ProfileSettings: Codable, Equatable {
    var id = UUID()
    var name = ""
}
