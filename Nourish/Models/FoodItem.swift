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

    // Serving and Base Nutrition
    var servingQuantity: Double?
    var servingUnitName: String?
    var baseCalories: Double?
    var baseProteinGrams: Double?
    var baseCarbsGrams: Double?
    var baseFatGrams: Double?

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
         dailyLog: DailyLog? = nil,
         servingQuantity: Double? = 1.0,
         servingUnitName: String? = "Serving",
         baseCalories: Double? = nil,
         baseProteinGrams: Double? = nil,
         baseCarbsGrams: Double? = nil,
         baseFatGrams: Double? = nil) {
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

        self.servingQuantity = servingQuantity
        self.servingUnitName = servingUnitName

        // If base is provided, use it. Otherwise, assume the provided total IS the base for 1 serving.
        self.baseCalories = baseCalories ?? (servingQuantity != nil && servingQuantity! > 0 ? calories / servingQuantity! : calories)
        self.baseProteinGrams = baseProteinGrams ?? (servingQuantity != nil && servingQuantity! > 0 ? proteinGrams / servingQuantity! : proteinGrams)
        self.baseCarbsGrams = baseCarbsGrams ?? (servingQuantity != nil && servingQuantity! > 0 ? carbsGrams / servingQuantity! : carbsGrams)
        self.baseFatGrams = baseFatGrams ?? (servingQuantity != nil && servingQuantity! > 0 ? fatGrams / servingQuantity! : fatGrams)
    }

    // Helper to recalculate total macros based on base macros and quantity
    func recalculateTotals() {
        let qty = servingQuantity ?? 1.0
        self.calories = (baseCalories ?? 0) * qty
        self.proteinGrams = (baseProteinGrams ?? 0) * qty
        self.carbsGrams = (baseCarbsGrams ?? 0) * qty
        self.fatGrams = (baseFatGrams ?? 0) * qty
    }
}
