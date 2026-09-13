import XCTest
import SwiftData
@testable import Nourish

@MainActor
final class OnboardingViewModelTests: XCTestCase {

    func testInitialState() {
        let vm = OnboardingViewModel()
        XCTAssertEqual(vm.currentStep, .welcome)
        XCTAssertEqual(vm.age, 28)
        XCTAssertEqual(vm.biologicalSex, .male)
        XCTAssertEqual(vm.heightCm, 175.0)
        XCTAssertEqual(vm.weightKg, 75.0)
        XCTAssertEqual(vm.activityLevel, .moderatelyActive)
        XCTAssertEqual(vm.goalType, .weightLoss)
        XCTAssertEqual(vm.weeklyWeightChangeKg, -0.5)
        XCTAssertEqual(vm.proteinPercentage, 30.0)
        XCTAssertEqual(vm.carbsPercentage, 40.0)
        XCTAssertEqual(vm.fatPercentage, 30.0)
        XCTAssertTrue(vm.canProceed)
    }

    func testStepNavigationForwardAndBackward() {
        let vm = OnboardingViewModel()

        XCTAssertEqual(vm.currentStep, .welcome)

        vm.nextStep()
        XCTAssertEqual(vm.currentStep, .biometrics)

        vm.nextStep()
        XCTAssertEqual(vm.currentStep, .activity)

        vm.nextStep()
        XCTAssertEqual(vm.currentStep, .goal)

        vm.nextStep()
        XCTAssertEqual(vm.currentStep, .pace)

        vm.nextStep()
        XCTAssertEqual(vm.currentStep, .macroSplit)

        vm.nextStep()
        XCTAssertEqual(vm.currentStep, .summary)

        // Cannot go past the last step
        vm.nextStep()
        XCTAssertEqual(vm.currentStep, .summary)

        // Go backward
        vm.previousStep()
        XCTAssertEqual(vm.currentStep, .macroSplit)

        vm.previousStep()
        XCTAssertEqual(vm.currentStep, .pace)

        vm.previousStep()
        XCTAssertEqual(vm.currentStep, .goal)

        vm.previousStep()
        XCTAssertEqual(vm.currentStep, .activity)

        vm.previousStep()
        XCTAssertEqual(vm.currentStep, .biometrics)

        vm.previousStep()
        XCTAssertEqual(vm.currentStep, .welcome)

        // Cannot go before first step
        vm.previousStep()
        XCTAssertEqual(vm.currentStep, .welcome)
    }

    func testValidationCanProceed() {
        let vm = OnboardingViewModel()

        // Valid defaults
        XCTAssertTrue(vm.canProceed)

        // Age invalid
        vm.age = 12
        XCTAssertFalse(vm.canProceed)
        vm.age = 101
        XCTAssertFalse(vm.canProceed)
        vm.age = 25
        XCTAssertTrue(vm.canProceed)

        // Height invalid
        vm.heightCm = 40.0
        XCTAssertFalse(vm.canProceed)
        vm.heightCm = 350.0
        XCTAssertFalse(vm.canProceed)
        vm.heightCm = 180.0
        XCTAssertTrue(vm.canProceed)

        // Weight invalid
        vm.weightKg = 15.0
        XCTAssertFalse(vm.canProceed)
        vm.weightKg = 600.0
        XCTAssertFalse(vm.canProceed)
        vm.weightKg = 70.0
        XCTAssertTrue(vm.canProceed)

        // Macros sum must be roughly 100
        vm.proteinPercentage = 50.0
        vm.carbsPercentage = 50.0
        vm.fatPercentage = 50.0
        XCTAssertFalse(vm.canProceed)

        vm.proteinPercentage = 30.0
        vm.carbsPercentage = 40.0
        vm.fatPercentage = 30.0
        XCTAssertTrue(vm.canProceed)
    }

    func testCalculations() {
        let vm = OnboardingViewModel()

        // BMR for 75kg, 175cm, 28yo, male
        // BMR = 10 * 75 + 6.25 * 175 - 5 * 28 + 5 = 750 + 1093.75 - 140 + 5 = 1708.75
        XCTAssertEqual(vm.calculatedBMR, 1708.75, accuracy: 0.01)

        // TDEE = 1708.75 * 1.55 (moderatelyActive) = 2648.5625
        XCTAssertEqual(vm.calculatedTDEE, 2648.5625, accuracy: 0.01)

        // Calories with weight loss (-0.5 kg/week)
        // daily deficit = (-0.5 * 7700) / 7 = -550 kcal/day
        // Calories = 2648.5625 - 550 = 2098.5625
        XCTAssertEqual(vm.calculatedDailyCalories, 2098.5625, accuracy: 0.01)

        // Macro targets
        let macros = vm.calculatedMacroTargets
        let expectedProtein = (2098.5625 * 0.30) / 4.0
        let expectedCarbs = (2098.5625 * 0.40) / 4.0
        let expectedFat = (2098.5625 * 0.30) / 9.0
        XCTAssertEqual(macros.protein, expectedProtein, accuracy: 0.01)
        XCTAssertEqual(macros.carbs, expectedCarbs, accuracy: 0.01)
        XCTAssertEqual(macros.fat, expectedFat, accuracy: 0.01)

        // Water intake: 75kg * 35ml = 2625ml = 2.625 L
        XCTAssertEqual(vm.waterIntakeLiters, 2.625, accuracy: 0.001)
    }

    func testCalorieFloorSafety() {
        let vm = OnboardingViewModel()
        vm.weightKg = 45.0
        vm.heightCm = 150.0
        vm.age = 50
        vm.biologicalSex = .female
        vm.activityLevel = .sedentary // 1.2
        vm.goalType = .weightLoss
        vm.weeklyWeightChangeKg = -1.0 // 1100 kcal deficit

        // TDEE is low, minus 1100 should go below 1200, so it clamps to 1200
        XCTAssertEqual(vm.calculatedDailyCalories, 1200.0)
    }

    func testGoalTypeAdjustments() {
        let vm = OnboardingViewModel()
        let baseTDEE = vm.calculatedTDEE

        // Weight Loss
        vm.goalType = .weightLoss
        vm.weeklyWeightChangeKg = -0.5
        XCTAssertEqual(vm.calculatedDailyCalories, baseTDEE - 550.0, accuracy: 0.01)

        // Weight Gain
        vm.goalType = .weightGain
        vm.weeklyWeightChangeKg = 0.5
        XCTAssertEqual(vm.calculatedDailyCalories, baseTDEE + 550.0, accuracy: 0.01)

        // Maintain
        vm.goalType = .maintain
        XCTAssertEqual(vm.calculatedDailyCalories, baseTDEE, accuracy: 0.01)
    }

    func testCreateUserProfileMapping() {
        let vm = OnboardingViewModel()
        vm.age = 32
        vm.weightKg = 80.0
        vm.heightCm = 182.0
        vm.biologicalSex = .female
        vm.activityLevel = .veryActive

        let profile = vm.createUserProfile()

        XCTAssertEqual(profile.age, 32)
        XCTAssertEqual(profile.weightInKg, 80.0)
        XCTAssertEqual(profile.heightInCm, 182.0)
        XCTAssertEqual(profile.biologicalSex, "female")
        XCTAssertEqual(profile.activityLevel, ActivityLevel.veryActive.rawValue)
        XCTAssertEqual(profile.targetDailyCalories, vm.calculatedDailyCalories)
        XCTAssertEqual(profile.targetProteinGrams, vm.calculatedMacroTargets.protein)
        XCTAssertEqual(profile.targetCarbsGrams, vm.calculatedMacroTargets.carbs)
        XCTAssertEqual(profile.targetFatGrams, vm.calculatedMacroTargets.fat)
        XCTAssertEqual(profile.targetWaterIntakeMl, 80.0 * 35.0)
    }

    func testSaveToSwiftData() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserProfile.self, configurations: config)
        let context = ModelContext(container)

        let vm = OnboardingViewModel()
        vm.saveToSwiftData(context: context)

        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = try context.fetch(descriptor)

        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.age, 28)
    }
}
