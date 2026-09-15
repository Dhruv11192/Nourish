import XCTest
import SwiftUI
@testable import Kalai

final class FoodSearchViewTests: XCTestCase {
    func testFoodSearchViewInstantiation() {
        let view = FoodSearchView(mealType: "Breakfast", selectedDate: .now, onFoodLogged: { _ in })
        XCTAssertNotNil(view)
    }

    func testFoodDetailModalViewCalculation() {
        let entry = CatalogFoodEntry(
            id: "1",
            name: "Egg",
            calories: 70,
            protein: 6,
            carbs: 0.5,
            fat: 5,
            servingSize: 1,
            servingUnit: "large"
        )
        let modal = FoodDetailModalView(food: entry, mealType: "Breakfast", onLog: { _ in })
        XCTAssertEqual(modal.calculatedCalories(servings: 2.0), 140)
    }
}
