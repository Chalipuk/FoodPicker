import Foundation

struct FoodGroup: Identifiable {
    let name: String
    let emoji: String
    let categories: [String]
    var id: String { name }
}
