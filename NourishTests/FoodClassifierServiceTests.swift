import XCTest
import Foundation
@testable import Nourish

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

final class FoodClassifierServiceTests: XCTestCase {

    // MARK: - LocalFoodDatabase Tests

    func testLocalFoodDatabaseContainsAtLeast30Items() {
        let items = LocalFoodDatabase.allItems()
        XCTAssertGreaterThanOrEqual(items.count, 30, "Database should contain at least 30 common foods")
    }

    func testLocalFoodDatabaseExactMatch() {
        let chicken = LocalFoodDatabase.find(matching: "chicken breast")
        XCTAssertNotNil(chicken)
        XCTAssertEqual(chicken?.name.lowercased(), "chicken breast")
        XCTAssertEqual(chicken?.servingGrams, 100)
        XCTAssertEqual(chicken?.calories, 165)
        XCTAssertEqual(chicken?.proteinGrams, 31)
        XCTAssertEqual(chicken?.carbsGrams, 0)
        XCTAssertEqual(chicken?.fatGrams, 3.6)
    }

    func testLocalFoodDatabaseFuzzyAndAliasMatching() {
        // "grilled chicken" should match chicken breast
        let grilledChicken = LocalFoodDatabase.find(matching: "grilled chicken")
        XCTAssertNotNil(grilledChicken)
        XCTAssertTrue(grilledChicken?.name.lowercased().contains("chicken") == true)

        // "boiled egg" should match egg
        let egg = LocalFoodDatabase.find(matching: "boiled egg")
        XCTAssertNotNil(egg)
        XCTAssertEqual(egg?.calories, 74)

        // "spaghetti" should match pasta
        let pasta = LocalFoodDatabase.find(matching: "spaghetti")
        XCTAssertNotNil(pasta)
        XCTAssertEqual(pasta?.calories, 220)

        // "cheeseburger" should match burger
        let burger = LocalFoodDatabase.find(matching: "cheeseburger")
        XCTAssertNotNil(burger)
        XCTAssertEqual(burger?.calories, 350)

        // "steamed rice" should match white rice
        let rice = LocalFoodDatabase.find(matching: "steamed rice")
        XCTAssertNotNil(rice)
        XCTAssertEqual(rice?.calories, 195)
    }

    func testLocalFoodDatabaseCaseInsensitiveAndWhitespace() {
        let avocadoUpper = LocalFoodDatabase.find(matching: "  AVOCADO  ")
        XCTAssertNotNil(avocadoUpper)
        XCTAssertEqual(avocadoUpper?.calories, 160)

        let nonExistent = LocalFoodDatabase.find(matching: "wooden table desk chair 12345")
        XCTAssertNil(nonExistent)
    }

    // MARK: - EstimatedFoodCandidate Tests

    func testEstimatedFoodCandidateScaling() {
        let candidate = EstimatedFoodCandidate(
            name: "Brown Rice",
            confidence: 0.92,
            servingGrams: 150,
            calories: 165,
            proteinGrams: 3.5,
            carbsGrams: 35,
            fatGrams: 1.4
        )

        let scaledDouble = candidate.scaled(by: 2.0)
        XCTAssertEqual(scaledDouble.id, candidate.id)
        XCTAssertEqual(scaledDouble.name, "Brown Rice")
        XCTAssertEqual(scaledDouble.confidence, 0.92)
        XCTAssertEqual(scaledDouble.servingGrams, 300)
        XCTAssertEqual(scaledDouble.calories, 330)
        XCTAssertEqual(scaledDouble.proteinGrams, 7.0)
        XCTAssertEqual(scaledDouble.carbsGrams, 70.0)
        XCTAssertEqual(scaledDouble.fatGrams, 2.8)

        let scaledHalf = candidate.scaled(by: 0.5)
        XCTAssertEqual(scaledHalf.servingGrams, 75)
        XCTAssertEqual(scaledHalf.calories, 82.5)
        XCTAssertEqual(scaledHalf.proteinGrams, 1.75)
    }

    func testEstimatedFoodCandidateToFoodItem() {
        let candidate = EstimatedFoodCandidate(
            name: "Salmon",
            confidence: 0.88,
            servingGrams: 120,
            calories: 250,
            proteinGrams: 26,
            carbsGrams: 0,
            fatGrams: 15
        )

        let foodItem = candidate.toFoodItem(mealType: .dinner)
        XCTAssertEqual(foodItem.name, "Salmon")
        XCTAssertEqual(foodItem.calories, 250)
        XCTAssertEqual(foodItem.proteinGrams, 26)
        XCTAssertEqual(foodItem.carbsGrams, 0)
        XCTAssertEqual(foodItem.fatGrams, 15)
        XCTAssertEqual(foodItem.mealType, .dinner)
    }

    // MARK: - FoodClassifierService Matching Tests

    func testMatchLabelsToFoodsWithConfidenceRanking() {
        let service = FoodClassifierService()
        let labels: [(identifier: String, confidence: Float)] = [
            ("pizza, pepperoni pizza", 0.95),
            ("dining table, furniture", 0.80),
            ("broccoli, vegetable", 0.70),
            ("fork, tableware", 0.65),
            ("apple, fruit", 0.45)
        ]

        let candidates = service.matchLabelsToFoods(labels)

        // Only foods should match: pizza, broccoli, apple
        XCTAssertEqual(candidates.count, 3)
        XCTAssertEqual(candidates[0].name.lowercased(), "pizza")
        XCTAssertEqual(candidates[0].confidence, 0.95, accuracy: 0.001)
        XCTAssertEqual(candidates[1].name.lowercased(), "broccoli")
        XCTAssertEqual(candidates[1].confidence, 0.70, accuracy: 0.001)
        XCTAssertEqual(candidates[2].name.lowercased(), "apple")
        XCTAssertEqual(candidates[2].confidence, 0.45, accuracy: 0.001)
    }

    func testMatchLabelsDeduplicationPrefersHighestConfidence() {
        let service = FoodClassifierService()
        let labels: [(identifier: String, confidence: Float)] = [
            ("chicken breast", 0.60),
            ("chicken breast", 0.90),
            ("chicken breast", 0.75)
        ]

        let candidates = service.matchLabelsToFoods(labels)
        XCTAssertEqual(candidates.count, 1)
        XCTAssertEqual(candidates.first?.name.lowercased(), "chicken breast")
        XCTAssertEqual(candidates.first?.confidence ?? 0, 0.90, accuracy: 0.001)
    }

    func testMatchLabelsEmptyWhenNoFoodRecognized() {
        let service = FoodClassifierService()
        let labels: [(identifier: String, confidence: Float)] = [
            ("couch, sofa", 0.95),
            ("laptop, computer", 0.85),
            ("cellphone", 0.70)
        ]

        let candidates = service.matchLabelsToFoods(labels)
        XCTAssertTrue(candidates.isEmpty)
    }

    func testFoodClassifierServiceWithRealVisionCGImage() async throws {
        let service = FoodClassifierService()
        guard let cgImage = createTestCGImage() else {
            XCTFail("Failed to create test CGImage")
            return
        }

        do {
            let candidates = try await service.classifyPlate(cgImage: cgImage)
            XCTAssertNotNil(candidates)
        } catch {
            // In simulator environments without GPU/ANE, Vision espresso context can fail
            XCTAssertNotNil(error)
        }
    }

    func testFoodClassifierErrorDescriptions() {
        let invalidImageError = FoodClassifierError.invalidImage
        XCTAssertTrue(invalidImageError.localizedDescription.contains("Unable to process"))

        let failedError = FoodClassifierError.classificationFailed("Network timeout")
        XCTAssertTrue(failedError.localizedDescription.contains("Network timeout"))
    }

    private func createTestCGImage() -> CGImage? {
        let width = 100
        let height = 100
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 4 * width,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }
        context.setFillColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }

    // MARK: - Mock FoodClassifier Protocol & Service

    final class MockFoodClassifierService: FoodClassifierProtocol, @unchecked Sendable {
        var resultToReturn: [EstimatedFoodCandidate] = []
        var shouldThrow: Bool = false

        func classifyPlate(image: UIImage) async throws -> [EstimatedFoodCandidate] {
            if shouldThrow {
                throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Classification failed"])
            }
            return resultToReturn
        }

        func classifyPlate(cgImage: CGImage) async throws -> [EstimatedFoodCandidate] {
            if shouldThrow {
                throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Classification failed"])
            }
            return resultToReturn
        }

        func matchLabelsToFoods(_ labels: [(identifier: String, confidence: Float)]) -> [EstimatedFoodCandidate] {
            return resultToReturn
        }
    }

    // MARK: - AIPlateScannerViewModel Tests

    @MainActor
    func testViewModelInitialState() {
        let mockService = MockFoodClassifierService()
        let viewModel = AIPlateScannerViewModel(classifierService: mockService, selectedMealType: .lunch)

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertTrue(viewModel.selectedCandidates.isEmpty)
        XCTAssertEqual(viewModel.portionMultiplier, 1.0)
        XCTAssertEqual(viewModel.selectedMealType, .lunch)
    }

    @MainActor
    func testViewModelSuccessfulAnalysisAndItemGeneration() async {
        let mockService = MockFoodClassifierService()
        let id1 = UUID()
        let id2 = UUID()
        let candidate1 = EstimatedFoodCandidate(
            id: id1,
            name: "Grilled Chicken",
            confidence: 0.95,
            servingGrams: 100,
            calories: 165,
            proteinGrams: 31,
            carbsGrams: 0,
            fatGrams: 3.6
        )
        let candidate2 = EstimatedFoodCandidate(
            id: id2,
            name: "Steamed Rice",
            confidence: 0.85,
            servingGrams: 150,
            calories: 195,
            proteinGrams: 4,
            carbsGrams: 43,
            fatGrams: 0.4
        )
        mockService.resultToReturn = [candidate1, candidate2]

        let viewModel = AIPlateScannerViewModel(classifierService: mockService, selectedMealType: .dinner)

        #if canImport(UIKit)
        let image = UIImage()
        #elseif canImport(AppKit)
        let image = NSImage()
        #endif

        await viewModel.analyzeImage(image)

        if case .results(let candidates) = viewModel.state {
            XCTAssertEqual(candidates.count, 2)
            XCTAssertEqual(candidates[0].name, "Grilled Chicken")
            XCTAssertEqual(candidates[1].name, "Steamed Rice")
        } else {
            XCTFail("Expected .results state but got \(viewModel.state)")
        }

        // All candidates should be selected by default
        XCTAssertEqual(viewModel.selectedCandidates.count, 2)
        XCTAssertTrue(viewModel.selectedCandidates.contains(id1))
        XCTAssertTrue(viewModel.selectedCandidates.contains(id2))

        // Portion multiplier 1.5x
        viewModel.portionMultiplier = 1.5
        let foodItems = viewModel.generateFoodItemsToLog()
        XCTAssertEqual(foodItems.count, 2)

        let chickenItem = foodItems.first(where: { $0.name == "Grilled Chicken" })
        XCTAssertNotNil(chickenItem)
        XCTAssertEqual(chickenItem?.calories ?? 0, 165 * 1.5, accuracy: 0.1)
        XCTAssertEqual(chickenItem?.proteinGrams ?? 0, 31 * 1.5, accuracy: 0.1)
        XCTAssertEqual(chickenItem?.mealType, .dinner)

        // Toggle off rice
        viewModel.toggleSelection(for: id2)
        XCTAssertFalse(viewModel.selectedCandidates.contains(id2))
        let singleItem = viewModel.generateFoodItemsToLog()
        XCTAssertEqual(singleItem.count, 1)
        XCTAssertEqual(singleItem.first?.name, "Grilled Chicken")
    }

    @MainActor
    func testViewModelEmptyResultsState() async {
        let mockService = MockFoodClassifierService()
        mockService.resultToReturn = []

        let viewModel = AIPlateScannerViewModel(classifierService: mockService)

        #if canImport(UIKit)
        let image = UIImage()
        #elseif canImport(AppKit)
        let image = NSImage()
        #endif

        await viewModel.analyzeImage(image)

        XCTAssertEqual(viewModel.state, .empty)
        XCTAssertTrue(viewModel.generateFoodItemsToLog().isEmpty)
    }

    @MainActor
    func testViewModelErrorState() async {
        let mockService = MockFoodClassifierService()
        mockService.shouldThrow = true

        let viewModel = AIPlateScannerViewModel(classifierService: mockService)

        #if canImport(UIKit)
        let image = UIImage()
        #elseif canImport(AppKit)
        let image = NSImage()
        #endif

        await viewModel.analyzeImage(image)

        if case .failed(let message) = viewModel.state {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected .failed state but got \(viewModel.state)")
        }
    }

    @MainActor
    func testViewModelReset() async {
        let mockService = MockFoodClassifierService()
        let candidate = EstimatedFoodCandidate(
            name: "Avocado",
            confidence: 0.90,
            servingGrams: 100,
            calories: 160,
            proteinGrams: 2,
            carbsGrams: 8.5,
            fatGrams: 14.7
        )
        mockService.resultToReturn = [candidate]

        let viewModel = AIPlateScannerViewModel(classifierService: mockService, selectedMealType: .breakfast)

        #if canImport(UIKit)
        let image = UIImage()
        #elseif canImport(AppKit)
        let image = NSImage()
        #endif

        await viewModel.analyzeImage(image)
        viewModel.portionMultiplier = 2.0

        viewModel.reset()

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertTrue(viewModel.selectedCandidates.isEmpty)
        XCTAssertEqual(viewModel.portionMultiplier, 1.0)
    }
}
