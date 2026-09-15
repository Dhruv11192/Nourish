import XCTest
@testable import Kalai

final class DataIngestorTests: XCTestCase {
    func testParseCatalogFood() throws {
        let jsonData = """
        {
            "id": "123",
            "name": "Apple",
            "category": "Fruits",
            "nutritional_contents": {
                "energy": { "unit": "calories", "value": 95 },
                "protein": 0.5,
                "carbohydrates": 25.0,
                "fat": 0.3
            },
            "serving_sizes": [
                { "unit": "fruit", "value": 1.0, "nutrition_multiplier": 1.0 }
            ]
        }
        """.data(using: .utf8)!

        let food = try JSONDecoder().decode(CatalogFood.self, from: jsonData)
        XCTAssertEqual(food.name, "Apple")
        XCTAssertEqual(food.nutritional_contents.energy.value, 95)
    }

    func testParseFoodsArray() throws {
        let jsonData = """
        [
            {
                "id": "123",
                "name": "Apple",
                "category": "Fruits",
                "nutritional_contents": {
                    "energy": { "unit": "calories", "value": 95 }
                },
                "serving_sizes": [
                    { "unit": "fruit", "value": 1.0, "nutrition_multiplier": 1.0 }
                ]
            }
        ]
        """.data(using: .utf8)!

        let foods = DataIngestor.parseFoods(from: jsonData)
        XCTAssertEqual(foods.count, 1)
        XCTAssertEqual(foods.first?.name, "Apple")
    }
}
