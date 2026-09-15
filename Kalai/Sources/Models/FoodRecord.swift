import Foundation
import SwiftData

@Model
class FoodRecord {
    var name: String
    var brand: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var portionSize: Double
    var portionUnit: String
    var date: Date

    init(name: String, brand: String = "", calories: Double, protein: Double, carbs: Double, fat: Double, portionSize: Double = 1.0, portionUnit: String = "serving", date: Date = .now) {
        self.name = name
        self.brand = brand
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.portionSize = portionSize
        self.portionUnit = portionUnit
        self.date = date
    }
}
