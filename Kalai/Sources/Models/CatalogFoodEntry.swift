import Foundation
import SwiftData

@Model
class CatalogFoodEntry {
    @Attribute(.unique) var id: String
    var name: String
    var brand: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var servingSize: Double
    var servingUnit: String
    var barcode: String?

    init(id: String = UUID().uuidString, name: String, brand: String = "", calories: Double, protein: Double, carbs: Double, fat: Double, servingSize: Double = 1.0, servingUnit: String = "serving", barcode: String? = nil) {
        self.id = id
        self.name = name
        self.brand = brand
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.barcode = barcode
    }
}
