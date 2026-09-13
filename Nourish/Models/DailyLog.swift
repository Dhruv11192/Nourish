import Foundation
import SwiftData

@Model
final class DailyLog {
    @Attribute(.unique)
    var dateString: String // Format: "yyyy-MM-dd"

    var activeEnergyBurnedKcal: Double
    var waterIntakeMl: Double

    @Relationship(deleteRule: .cascade)
    var foodItems: [FoodItem] = []

    init(dateString: String, activeEnergyBurnedKcal: Double = 0.0, waterIntakeMl: Double = 0.0, foodItems: [FoodItem] = []) {
        self.dateString = dateString
        self.activeEnergyBurnedKcal = activeEnergyBurnedKcal
        self.waterIntakeMl = waterIntakeMl
        self.foodItems = foodItems
    }

    // Computed properties for aggregates
    @Transient
    var totalCalories: Double {
        foodItems.reduce(0) { $0 + $1.calories }
    }

    @Transient
    var totalProtein: Double {
        foodItems.reduce(0) { $0 + $1.proteinGrams }
    }

    @Transient
    var totalCarbs: Double {
        foodItems.reduce(0) { $0 + $1.carbsGrams }
    }

    @Transient
    var totalFat: Double {
        foodItems.reduce(0) { $0 + $1.fatGrams }
    }

    // Helper to get items grouped by meal type
    func foodItems(for type: MealType) -> [FoodItem] {
        foodItems.filter { $0.mealType == type }
    }
}
