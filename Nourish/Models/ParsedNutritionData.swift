import Foundation

public struct ParsedNutritionData: Equatable, Sendable {
    public var calories: Double?
    public var protein: Double?
    public var carbs: Double?
    public var fat: Double?
    public var servingSize: String?
    public var servingWeightGrams: Double?

    public init(
        calories: Double? = nil,
        protein: Double? = nil,
        carbs: Double? = nil,
        fat: Double? = nil,
        servingSize: String? = nil,
        servingWeightGrams: Double? = nil
    ) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingSize = servingSize
        self.servingWeightGrams = servingWeightGrams
    }

    public var isValid: Bool {
        calories != nil || protein != nil || carbs != nil || fat != nil
    }

    func toFoodItem(name: String = "Scanned Food", mealType: MealType = .snack) -> FoodItem {
        FoodItem(
            name: name,
            calories: calories ?? 0,
            proteinGrams: protein ?? 0,
            carbsGrams: carbs ?? 0,
            fatGrams: fat ?? 0,
            mealType: mealType,
            servingQuantity: 1.0,
            servingUnitName: servingSize ?? "Serving",
            baseCalories: calories ?? 0,
            baseProteinGrams: protein ?? 0,
            baseCarbsGrams: carbs ?? 0,
            baseFatGrams: fat ?? 0
        )
    }
}
