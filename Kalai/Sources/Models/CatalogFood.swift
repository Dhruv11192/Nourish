import Foundation

struct CatalogFood: Codable, Identifiable {
    let id: String
    let name: String
    let category: String?
    let nutritional_contents: NutritionContents
    let serving_sizes: [ServingSize]
}

struct NutritionContents: Codable {
    let energy: EnergyValue
    let protein: Double?
    let carbohydrates: Double?
    let fat: Double?
}

struct EnergyValue: Codable {
    let unit: String
    let value: Double
}

struct ServingSize: Codable {
    let unit: String
    let value: Double
    let nutrition_multiplier: Double
}
