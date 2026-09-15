import Foundation
import SwiftData

@Model
class DailyDiary {
    var date: Date
    @Relationship(deleteRule: .cascade) var foods: [FoodRecord]

    init(date: Date = .now, foods: [FoodRecord] = []) {
        self.date = date
        self.foods = foods
    }

    var totalCalories: Double {
        foods.reduce(0) { $0 + $1.calories }
    }
}
