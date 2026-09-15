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
    var mealType: String
    var date: Date

    init(name: String, brand: String = "", calories: Double, protein: Double, carbs: Double, fat: Double, portionSize: Double = 1.0, portionUnit: String = "serving", mealType: String = "Breakfast", date: Date = .now) {
        self.name = name
        self.brand = brand
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.portionSize = portionSize
        self.portionUnit = portionUnit
        self.mealType = mealType
        self.date = date
    }
}
