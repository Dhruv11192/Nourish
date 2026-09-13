import XCTest
@testable import Nourish

final class NutritionOCRParserTests: XCTestCase {

    // MARK: - Testing US standard label lines
    func testParseUSLabels() {
        let lines = [
            "Nutrition Facts",
            "Serving Size 1 cup (228g)",
            "Calories 230",
            "Total Fat 8g 10%",
            "Total Carbohydrate 37g",
            "Protein 3g"
        ]

        let data = NutritionOCRParser.parseNutritionFacts(from: lines)

        XCTAssertEqual(data.calories, 230)
        XCTAssertEqual(data.fat, 8)
        XCTAssertEqual(data.carbs, 37)
        XCTAssertEqual(data.protein, 3)
        XCTAssertEqual(data.servingWeightGrams, 228)
        XCTAssertNotNil(data.servingSize)
        XCTAssertTrue(data.isValid)
    }

    // MARK: - Testing European label lines (kJ/kcal parsing)
    func testParseEuropeanLabels() {
        let lines = [
            "Energy 850 kJ / 200 kcal",
            "Fat 7.2g",
            "Carbohydrate 28.0g",
            "Protein 4.5g"
        ]

        let data = NutritionOCRParser.parseNutritionFacts(from: lines)

        XCTAssertEqual(data.calories, 200)
        XCTAssertEqual(data.fat, 7.2)
        XCTAssertEqual(data.carbs, 28.0)
        XCTAssertEqual(data.protein, 4.5)
        XCTAssertTrue(data.isValid)
    }

    func testParseEuropeanLabelsKJOnlyConversion() {
        let lines = [
            "Energy 837 kJ",
            "Fat 5g",
            "Carbohydrate 10g",
            "Protein 2g"
        ]

        let data = NutritionOCRParser.parseNutritionFacts(from: lines)

        // 837 / 4.184 = 200.047 -> rounded is 200
        XCTAssertEqual(data.calories, 200)
        XCTAssertEqual(data.fat, 5)
        XCTAssertEqual(data.carbs, 10)
        XCTAssertEqual(data.protein, 2)
    }

    // MARK: - Testing multi-line text arrays where keywords and numeric values are on adjacent lines
    func testParseMultiLineAdjacentValues() {
        let lines = [
            "Calories",
            "150",
            "Total Fat",
            "10.5g",
            "Carbs",
            "12 g",
            "Protein",
            "5"
        ]

        let data = NutritionOCRParser.parseNutritionFacts(from: lines)

        XCTAssertEqual(data.calories, 150)
        XCTAssertEqual(data.fat, 10.5)
        XCTAssertEqual(data.carbs, 12)
        XCTAssertEqual(data.protein, 5)
    }

    // MARK: - Testing edge cases: 0g fats/carbs, decimal values, percentages present, noise lines, missing values
    func testParseEdgeCases() {
        let text = """
        RANDOM NOISE
        Calories 0
        Total Fat 0g 0%
        Cholesterol 10mg 3%
        Sodium 50mg 2%
        Total Carbohydrate 0.5g 1%
        Protein 0 g
        """

        let data = NutritionOCRParser.parseNutritionFacts(from: text)
        XCTAssertEqual(data.calories, 0)
        XCTAssertEqual(data.fat, 0)
        XCTAssertEqual(data.carbs, 0.5)
        XCTAssertEqual(data.protein, 0)
        XCTAssertTrue(data.isValid)
    }

    func testParsePercentageStrippingAndDecimals() {
        let lines = [
            "Total Fat 9.5g 12% DV",
            "Total Carbohydrate 25,5g 8% DV",
            "Protein 15.0g 30% DV",
            "Calories 250"
        ]

        let data = NutritionOCRParser.parseNutritionFacts(from: lines)
        XCTAssertEqual(data.fat, 9.5)
        XCTAssertEqual(data.carbs, 25.5)
        XCTAssertEqual(data.protein, 15.0)
        XCTAssertEqual(data.calories, 250)
    }

    func testParseServingWeightExtractionVariations() {
        let lines1 = ["Serving Size 1 bar (55g)", "Calories 200"]
        let data1 = NutritionOCRParser.parseNutritionFacts(from: lines1)
        XCTAssertEqual(data1.servingWeightGrams, 55)

        let lines2 = ["Per 100g", "Calories 400"]
        let data2 = NutritionOCRParser.parseNutritionFacts(from: lines2)
        XCTAssertEqual(data2.servingWeightGrams, 100)

        let lines3 = ["Serving Size: 50g", "Calories 150"]
        let data3 = NutritionOCRParser.parseNutritionFacts(from: lines3)
        XCTAssertEqual(data3.servingWeightGrams, 50)
    }

    func testParseMissingValues() {
        let lines = [
            "Just some random text",
            "No nutrition info here"
        ]

        let data = NutritionOCRParser.parseNutritionFacts(from: lines)
        XCTAssertFalse(data.isValid)
        XCTAssertNil(data.calories)
        XCTAssertNil(data.fat)
        XCTAssertNil(data.carbs)
        XCTAssertNil(data.protein)
    }

    // MARK: - Testing OCRScannerViewModel processing
    @MainActor
    func testOCRScannerViewModelProcessingAndFoodItemCreation() async {
        let viewModel = OCRScannerViewModel()

        XCTAssertEqual(viewModel.state, .idle)

        let lines = [
            "Calories 150",
            "Fat 5g",
            "Carbohydrate 20g",
            "Protein 8g"
        ]

        viewModel.processRecognizedLines(lines)

        // Ensure state changed to recognized
        if case let .recognized(data) = viewModel.state {
            XCTAssertEqual(data.calories, 150)
            XCTAssertEqual(data.fat, 5)
            XCTAssertEqual(data.carbs, 20)
            XCTAssertEqual(data.protein, 8)
        } else {
            XCTFail("ViewModel state should be recognized but is \(viewModel.state)")
        }

        viewModel.nameInput = "Protein Bar"
        viewModel.selectedMealType = .snack

        let foodItem = viewModel.createFoodItem()
        XCTAssertNotNil(foodItem)
        XCTAssertEqual(foodItem?.name, "Protein Bar")
        XCTAssertEqual(foodItem?.mealType, .snack)
        XCTAssertEqual(foodItem?.calories, 150)
        XCTAssertEqual(foodItem?.fatGrams, 5)
        XCTAssertEqual(foodItem?.carbsGrams, 20)
        XCTAssertEqual(foodItem?.proteinGrams, 8)

        viewModel.reset()
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNil(viewModel.parsedData)
        XCTAssertTrue(viewModel.recognizedLines.isEmpty)
        XCTAssertEqual(viewModel.nameInput, "")
    }

    @MainActor
    func testOCRScannerViewModelUnrecognizedLines() {
        let viewModel = OCRScannerViewModel()
        viewModel.processRecognizedLines(["Unrelated text", "Another line"])

        if case let .failed(msg) = viewModel.state {
            XCTAssertFalse(msg.isEmpty)
        } else {
            XCTFail("Expected .failed state")
        }

        XCTAssertNil(viewModel.createFoodItem())
    }

    @MainActor
    func testOCRScannerViewModelDefaultName() {
        let viewModel = OCRScannerViewModel()
        viewModel.processRecognizedLines(["Calories 100", "Protein 10g"])
        viewModel.nameInput = "   " // blank
        let foodItem = viewModel.createFoodItem()
        XCTAssertEqual(foodItem?.name, "Scanned Food")
    }
}
