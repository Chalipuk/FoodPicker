import Foundation

struct HistoryEntry: Identifiable, Codable {
    var id = UUID()
    let food: Food
    let date: Date
}
