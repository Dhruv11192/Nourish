import Foundation
import SwiftData

enum DataSeeder {
    static func seedInitialFoods(into context: ModelContext, foodsData: Data) {
        let parsedFoods = DataIngestor.parseFoods(from: foodsData)
        guard !parsedFoods.isEmpty else { return }

        for food in parsedFoods {
            let serving = food.serving_sizes.first
            let entry = CatalogFoodEntry(
                id: food.id,
                name: food.name,
                brand: food.category ?? "",
                calories: food.nutritional_contents.energy.value,
                protein: food.nutritional_contents.protein ?? 0.0,
                carbs: food.nutritional_contents.carbohydrates ?? 0.0,
                fat: food.nutritional_contents.fat ?? 0.0,
                servingSize: serving?.value ?? 1.0,
                servingUnit: serving?.unit ?? "serving",
                barcode: nil
            )
            context.insert(entry)
        }

        try? context.save()
    }
}
