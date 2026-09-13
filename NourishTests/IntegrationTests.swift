import XCTest
import SwiftData
import HealthKit
@testable import Nourish

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
typealias UIImage = NSImage
#endif

@MainActor
final class IntegrationTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: UserProfile.self, DailyLog.self, FoodItem.self, configurations: config)
        context = ModelContext(container)
    }

    override func tearDown() {
        container = nil
        context = nil
    }

    // MARK: - Integration Tests

    func testCompleteOnboardingToDailyLoggingFlow() async throws {
        // 1. Create OnboardingViewModel and configure biometrics
        let onBoardingVM = OnboardingViewModel()
        onBoardingVM.biologicalSex = .male
        onBoardingVM.age = 28
        onBoardingVM.heightCm = 180.0
        onBoardingVM.weightKg = 80.0
        onBoardingVM.activityLevel = .moderatelyActive
        onBoardingVM.goalType = .weightLoss
        onBoardingVM.weeklyWeightChangeKg = -0.5
        onBoardingVM.proteinPercentage = 30.0
        onBoardingVM.carbsPercentage = 40.0
        onBoardingVM.fatPercentage = 30.0

        XCTAssertTrue(onBoardingVM.canProceed)

        // 2. Assert correct BMR, TDEE, Calorie Target, and Macro targets in grams
        let expectedBMR = 10.0 * 80.0 + 6.25 * 180.0 - 5.0 * 28.0 + 5.0 // 1790.0
        XCTAssertEqual(onBoardingVM.calculatedBMR, expectedBMR, accuracy: 0.01)

        let expectedTDEE = expectedBMR * 1.55 // 2774.5
        XCTAssertEqual(onBoardingVM.calculatedTDEE, expectedTDEE, accuracy: 0.01)

        let expectedCalories = expectedTDEE - 550.0 // 2224.5
        XCTAssertEqual(onBoardingVM.calculatedDailyCalories, expectedCalories, accuracy: 0.01)

        let macroTargets = onBoardingVM.calculatedMacroTargets
        let expectedProtein = (expectedCalories * 0.30) / 4.0 // 166.8375
        let expectedCarbs = (expectedCalories * 0.40) / 4.0 // 222.45
        let expectedFat = (expectedCalories * 0.30) / 9.0 // 74.15
        XCTAssertEqual(macroTargets.protein, expectedProtein, accuracy: 0.01)
        XCTAssertEqual(macroTargets.carbs, expectedCarbs, accuracy: 0.01)
        XCTAssertEqual(macroTargets.fat, expectedFat, accuracy: 0.01)
        XCTAssertEqual(onBoardingVM.waterIntakeLiters, (80.0 * 35.0) / 1000.0, accuracy: 0.001)

        // 3. Export to UserProfile
        onBoardingVM.saveToSwiftData(context: context)
        let profileDescriptor = FetchDescriptor<UserProfile>()
        let profiles = try context.fetch(profileDescriptor)
        XCTAssertEqual(profiles.count, 1)
        let savedProfile = try XCTUnwrap(profiles.first)
        XCTAssertEqual(savedProfile.targetDailyCalories, expectedCalories, accuracy: 0.01)
        XCTAssertEqual(savedProfile.targetProteinGrams, expectedProtein, accuracy: 0.01)
        XCTAssertEqual(savedProfile.targetWaterIntakeMl, 2800.0, accuracy: 0.01)

        // 4. Create DailyLog for today & initialize DashboardViewModel with MockHealthKitService
        let mockHKService = MockHealthKitService(isAvailable: true)
        mockHKService.mockActiveEnergy = 350.0
        mockHKService.mockSteps = 8500

        let dashboardVM = DashboardViewModel(healthKitService: mockHKService)
        dashboardVM.loadData(context: context)
        try await Task.sleep(nanoseconds: 50_000_000)

        let dailyLog = try XCTUnwrap(dashboardVM.todayLog)
        XCTAssertEqual(dashboardVM.steps, 8500)
        XCTAssertEqual(dailyLog.activeEnergyBurnedKcal, 350.0)

        // 5. Simulate Breakfast entry from Barcode scanning (OpenFoodFactsService / BarcodeScannerViewModel)
        let mockOFFService = MockOpenFoodFactsService()
        let breakfastItem = FoodItem(
            name: "Greek Yogurt & Granola",
            barcode: "737628064502",
            brand: "HealthyStart",
            calories: 320,
            proteinGrams: 22,
            carbsGrams: 45,
            fatGrams: 6,
            mealType: .breakfast
        )
        mockOFFService.stubbedResult = .success(breakfastItem)
        let barcodeVM = BarcodeScannerViewModel(service: mockOFFService)
        barcodeVM.startScanning()
        await barcodeVM.processScannedBarcode("737628064502")

        let scannedBreakfast = try XCTUnwrap(barcodeVM.scannedFoodItem)
        scannedBreakfast.mealType = .breakfast
        dailyLog.foodItems.append(scannedBreakfast)
        context.insert(scannedBreakfast)
        try await mockHKService.exportFoodEntry(scannedBreakfast)

        // 6. Simulate Lunch entry from AI Plate recognition (FoodClassifierService / AIPlateScannerViewModel)
        let mockClassifier = MockIntegrationFoodClassifierService()
        let chickenCandidate = EstimatedFoodCandidate(
            name: "Chicken Breast",
            confidence: 0.95,
            servingGrams: 150,
            calories: 247.5,
            proteinGrams: 46.5,
            carbsGrams: 0,
            fatGrams: 5.4
        )
        let riceCandidate = EstimatedFoodCandidate(
            name: "White Rice",
            confidence: 0.90,
            servingGrams: 150,
            calories: 195,
            proteinGrams: 4,
            carbsGrams: 43,
            fatGrams: 0.4
        )
        mockClassifier.stubbedCandidates = [chickenCandidate, riceCandidate]
        let aiVM = AIPlateScannerViewModel(classifierService: mockClassifier, selectedMealType: .lunch)
        await aiVM.analyzeImage(UIImage())
        XCTAssertEqual(aiVM.selectedCandidates.count, 2)

        let lunchItems = aiVM.generateFoodItemsToLog()
        XCTAssertEqual(lunchItems.count, 2)
        for item in lunchItems {
            dailyLog.foodItems.append(item)
            context.insert(item)
            try await mockHKService.exportFoodEntry(item)
        }

        // 7. Simulate Dinner entry from Nutrition Label OCR (NutritionOCRParser / OCRScannerViewModel)
        let ocrVM = OCRScannerViewModel()
        ocrVM.selectedMealType = .dinner
        ocrVM.nameInput = "Baked Salmon"
        ocrVM.processRecognizedLines([
            "Nutrition Facts",
            "Calories 400",
            "Total Fat 24g",
            "Total Carbohydrate 0g",
            "Protein 42g"
        ])
        let dinnerItem = try XCTUnwrap(ocrVM.createFoodItem())
        dailyLog.foodItems.append(dinnerItem)
        context.insert(dinnerItem)
        try await mockHKService.exportFoodEntry(dinnerItem)

        // 8. Simulate Water intake logging (+500ml)
        dashboardVM.addWater(amountMl: 500, context: context)
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(dailyLog.waterIntakeMl, 500.0)

        // 9. Verify HealthKit exports
        XCTAssertEqual(mockHKService.exportedFoodEntries.count, 4) // 1 breakfast + 2 lunch + 1 dinner
        XCTAssertEqual(mockHKService.exportedWaterEntries.count, 1)
        XCTAssertEqual(mockHKService.exportedWaterEntries.first?.liters, 0.5)

        // 10. Asserts total calories consumed, calories burned offset, remaining calories calculation, macro totals vs targets, and water percentage progress
        try context.save()

        let totalCaloriesConsumed = 320.0 + 247.5 + 195.0 + 400.0 // 1162.5 kcal
        XCTAssertEqual(dailyLog.totalCalories, totalCaloriesConsumed, accuracy: 0.01)
        XCTAssertEqual(dashboardVM.consumedCalories, totalCaloriesConsumed, accuracy: 0.01)

        let burnedCalories = 350.0
        XCTAssertEqual(dailyLog.activeEnergyBurnedKcal, burnedCalories, accuracy: 0.01)
        XCTAssertEqual(dashboardVM.burnedCalories, burnedCalories, accuracy: 0.01)

        let expectedRemainingCalories = expectedCalories - totalCaloriesConsumed + burnedCalories // 2224.5 - 1162.5 + 350 = 1412.0
        XCTAssertEqual(dashboardVM.caloriesRemaining, expectedRemainingCalories, accuracy: 0.01)

        let totalProteinConsumed = 22.0 + 46.5 + 4.0 + 42.0 // 114.5g
        let totalCarbsConsumed = 45.0 + 0.0 + 43.0 + 0.0 // 88.0g
        let totalFatConsumed = 6.0 + 5.4 + 0.4 + 24.0 // 35.8g

        XCTAssertEqual(dailyLog.totalProtein, totalProteinConsumed, accuracy: 0.01)
        XCTAssertEqual(dailyLog.totalCarbs, totalCarbsConsumed, accuracy: 0.01)
        XCTAssertEqual(dailyLog.totalFat, totalFatConsumed, accuracy: 0.01)

        XCTAssertEqual(dashboardVM.proteinProgress, totalProteinConsumed / expectedProtein, accuracy: 0.01)
        XCTAssertEqual(dashboardVM.carbsProgress, totalCarbsConsumed / expectedCarbs, accuracy: 0.01)
        XCTAssertEqual(dashboardVM.fatProgress, totalFatConsumed / expectedFat, accuracy: 0.01)

        let expectedWaterProgress = 500.0 / 2800.0
        XCTAssertEqual(dashboardVM.waterProgress, expectedWaterProgress, accuracy: 0.01)
    }

    func testCalorieSafetyFloorResilience() {
        let vm = OnboardingViewModel()
        vm.weightKg = 40
        vm.heightCm = 150
        vm.age = 50
        vm.biologicalSex = .female
        vm.activityLevel = .sedentary
        vm.goalType = .weightLoss
        vm.weeklyWeightChangeKg = -2.0 // Extreme deficit

        XCTAssertEqual(vm.calculatedDailyCalories, 1200.0)
    }

    func testHealthKitUnavailableGracefulDegradation() async throws {
        let mockHK = MockHealthKitService(isAvailable: false)
        let vm = DashboardViewModel(healthKitService: mockHK)

        // This should not throw/crash and handle gracefully
        vm.loadData(context: context)

        // Give the async task a moment to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // State remains defaults or 0 due to graceful failure
        XCTAssertEqual(vm.steps, 0)
        XCTAssertEqual(vm.burnedCalories, 0)
        XCTAssertFalse(vm.isLoading) // Should have flipped back to false even if HealthKit is unavailable
        XCTAssertNil(vm.error) // Depending on implementation, it might not set standard error for unavailability
    }

    func testEmptyDailyLogState() {
        let log = DailyLog(dateString: "2026-09-13")
        XCTAssertEqual(log.totalCalories, 0)
        XCTAssertEqual(log.totalProtein, 0)
        XCTAssertTrue(log.foodItems.isEmpty)
    }
}

// MARK: - Integration Tests Mocks

final class MockIntegrationFoodClassifierService: FoodClassifierProtocol, @unchecked Sendable {
    var stubbedCandidates: [EstimatedFoodCandidate] = []
    func classifyPlate(image: UIImage) async throws -> [EstimatedFoodCandidate] { return stubbedCandidates }
    func classifyPlate(cgImage: CGImage) async throws -> [EstimatedFoodCandidate] { return stubbedCandidates }
    func matchLabelsToFoods(_ labels: [(identifier: String, confidence: Float)]) -> [EstimatedFoodCandidate] { return stubbedCandidates }
}
