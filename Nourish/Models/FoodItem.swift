import Foundation
import SwiftData

@Model
final class FoodItem {
    var name: String
    var barcode: String?
    var brand: String?

    // Nutrition per serving
    var calories: Double
    var proteinGrams: Double
    var carbsGrams: Double
    var fatGrams: Double

    // Context
    var mealType: MealType
    var timestamp: Date

    @Relationship(inverse: \DailyLog.foodItems)
    var dailyLog: DailyLog?

    init(name: String,
         barcode: String? = nil,
         brand: String? = nil,
         calories: Double = 0.0,
         proteinGrams: Double = 0.0,
         carbsGrams: Double = 0.0,
         fatGrams: Double = 0.0,
         mealType: MealType = .snack,
         timestamp: Date = Date(),
         dailyLog: DailyLog? = nil) {
        self.name = name
        self.barcode = barcode
        self.brand = brand
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.mealType = mealType
        self.timestamp = timestamp
        self.dailyLog = dailyLog
    }
}
