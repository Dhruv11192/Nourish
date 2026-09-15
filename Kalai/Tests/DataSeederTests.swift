// Kalai/Tests/DataSeederTests.swift
import XCTest
import SwiftData
@testable import Kalai

final class DataSeederTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: CatalogFoodEntry.self, configurations: config)
        context = ModelContext(container)
    }

    func testSeedInitialFoods() throws {
        let json = """
        [
            {
                "id": "item_1",
                "name": "Banana",
                "category": "Produce",
                "nutritional_contents": {
                    "energy": { "unit": "calories", "value": 105.0 },
                    "protein": 1.3,
                    "carbohydrates": 27.0,
                    "fat": 0.3
                },
                "serving_sizes": [
                    { "unit": "medium", "value": 1.0, "nutrition_multiplier": 1.0 }
                ]
            }
        ]
        """.data(using: .utf8)!

        DataSeeder.seedInitialFoods(into: context, foodsData: json)

        let descriptor = FetchDescriptor<CatalogFoodEntry>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Banana")
        XCTAssertEqual(results.first?.calories, 105.0)
    }
}
