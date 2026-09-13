import XCTest
import SwiftData
@testable import Nourish

final class CalorieCalculationEngineTests: XCTestCase {

    // MARK: - BMR (Mifflin-St Jeor) Tests

    func testCalculateBMRForMale() {
        // Given: 30yo male, 70kg, 175cm
        // Formula: (10 * 70) + (6.25 * 175) - (5 * 30) + 5
        // 700 + 1093.75 - 150 + 5 = 1648.75
        let bmr = CalorieCalculationEngine.calculateBMR(
            weightInKg: 70.0,
            heightInCm: 175.0,
            age: 30,
            biologicalSex: .male
        )
        XCTAssertEqual(bmr, 1648.75, accuracy: 0.01)
    }

    func testCalculateBMRForFemale() {
        // Given: 25yo female, 60kg, 165cm
        // Formula: (10 * 60) + (6.25 * 165) - (5 * 25) - 161
        // 600 + 1031.25 - 125 - 161 = 1345.25
        let bmr = CalorieCalculationEngine.calculateBMR(
            weightInKg: 60.0,
            heightInCm: 165.0,
            age: 25,
            biologicalSex: .female
        )
        XCTAssertEqual(bmr, 1345.25, accuracy: 0.01)
    }

    func testCalculateBMRWithStringBiologicalSex() {
        let maleBMR = CalorieCalculationEngine.calculateBMR(
            weightInKg: 80.0,
            heightInCm: 180.0,
            age: 28,
            biologicalSex: "male"
        )
        // 10*80 + 6.25*180 - 5*28 + 5 = 800 + 1125 - 140 + 5 = 1790
        XCTAssertEqual(maleBMR, 1790.0, accuracy: 0.01)

        let femaleBMR = CalorieCalculationEngine.calculateBMR(
            weightInKg: 55.0,
            heightInCm: 160.0,
            age: 32,
            biologicalSex: "female"
        )
        // 10*55 + 6.25*160 - 5*32 - 161 = 550 + 1000 - 160 - 161 = 1229
        XCTAssertEqual(femaleBMR, 1229.0, accuracy: 0.01)
    }

    func testCalculateBMRFromUserProfile() {
        let profile = UserProfile(
            age: 30,
            weightInKg: 70.0,
            heightInCm: 175.0,
            biologicalSex: "male"
        )
        let bmr = CalorieCalculationEngine.calculateBMR(for: profile)
        XCTAssertEqual(bmr, 1648.75, accuracy: 0.01)
    }

    // MARK: - TDEE Tests

    func testCalculateTDEEWithStandardMultipliers() {
        let bmr = 1648.75

        // Sedentary (1.2)
        let sedentaryTDEE = CalorieCalculationEngine.calculateTDEE(bmr: bmr, activityMultiplier: 1.2)
        XCTAssertEqual(sedentaryTDEE, 1648.75 * 1.2, accuracy: 0.01)

        // Lightly Active (1.375)
        let lightTDEE = CalorieCalculationEngine.calculateTDEE(bmr: bmr, activityLevel: .lightlyActive)
        XCTAssertEqual(lightTDEE, 1648.75 * 1.375, accuracy: 0.01)

        // Moderately Active (1.55)
        let moderateTDEE = CalorieCalculationEngine.calculateTDEE(bmr: bmr, activityLevel: .moderatelyActive)
        XCTAssertEqual(moderateTDEE, 1648.75 * 1.55, accuracy: 0.01)

        // Active / Very Active (1.725)
        let activeTDEE = CalorieCalculationEngine.calculateTDEE(bmr: bmr, activityLevel: .veryActive)
        XCTAssertEqual(activeTDEE, 1648.75 * 1.725, accuracy: 0.01)

        // Extremely Active (1.9)
        let extremeTDEE = CalorieCalculationEngine.calculateTDEE(bmr: bmr, activityLevel: .extremelyActive)
        XCTAssertEqual(extremeTDEE, 1648.75 * 1.9, accuracy: 0.01)
    }

    func testCalculateTDEEFromUserProfile() {
        let profile = UserProfile(
            age: 30,
            weightInKg: 70.0,
            heightInCm: 175.0,
            biologicalSex: "male",
            activityLevel: 1.55
        )
        let tdee = CalorieCalculationEngine.calculateTDEE(for: profile)
        // BMR = 1648.75, TDEE = 1648.75 * 1.55 = 2555.5625
        XCTAssertEqual(tdee, 2555.5625, accuracy: 0.01)
    }

    // MARK: - Macro Split Tests

    func testCalculateMacroTargetsDefaultSplit() {
        // Total: 2000 kcal, Split: 30% P, 40% C, 30% F
        // Protein: 2000 * 0.30 = 600 kcal / 4 = 150g
        // Carbs: 2000 * 0.40 = 800 kcal / 4 = 200g
        // Fat: 2000 * 0.30 = 600 kcal / 9 = 66.666...g
        let macros = CalorieCalculationEngine.calculateMacroTargets(
            totalCalories: 2000.0,
            proteinPercentage: 0.30,
            carbsPercentage: 0.40,
            fatPercentage: 0.30
        )

        XCTAssertEqual(macros.calories, 2000.0, accuracy: 0.01)
        XCTAssertEqual(macros.proteinGrams, 150.0, accuracy: 0.01)
        XCTAssertEqual(macros.carbsGrams, 200.0, accuracy: 0.01)
        XCTAssertEqual(macros.fatGrams, 66.67, accuracy: 0.1)
    }

    func testCalculateMacroTargetsCustomMacroSplit() {
        // High protein: 40% P, 30% C, 30% F on 2500 kcal
        // Protein: 2500 * 0.40 = 1000 / 4 = 250g
        // Carbs: 2500 * 0.30 = 750 / 4 = 187.5g
        // Fat: 2500 * 0.30 = 750 / 9 = 83.33g
        let split = MacroSplit(proteinPercentage: 40, carbsPercentage: 30, fatPercentage: 30)
        let macros = CalorieCalculationEngine.calculateMacroTargets(totalCalories: 2500.0, split: split)

        XCTAssertEqual(macros.proteinGrams, 250.0, accuracy: 0.01)
        XCTAssertEqual(macros.carbsGrams, 187.5, accuracy: 0.01)
        XCTAssertEqual(macros.fatGrams, 83.33, accuracy: 0.1)
    }

    func testCalculateWaterIntake() {
        // 70kg -> 70 * 35ml = 2450ml
        let water = CalorieCalculationEngine.calculateWaterIntake(weightInKg: 70.0)
        XCTAssertEqual(water, 2450.0, accuracy: 0.01)
    }

    // MARK: - Recalculate Goals Integration

    func testRecalculateGoalsForUserProfile() {
        let profile = UserProfile(
            age: 30,
            weightInKg: 70.0,
            heightInCm: 175.0,
            biologicalSex: "male",
            activityLevel: 1.2
        )

        // BMR = 1648.75, TDEE = 1978.5
        // Goal deficit: -300 kcal -> targetDailyCalories = 1678.5
        // Macro split: 30/40/30
        // Protein: 1678.5 * 0.3 / 4 = 125.8875g
        // Carbs: 1678.5 * 0.4 / 4 = 167.85g
        // Fat: 1678.5 * 0.3 / 9 = 55.95g
        // Water: 70 * 35 = 2450ml
        CalorieCalculationEngine.recalculateGoals(
            for: profile,
            calorieAdjustment: -300.0,
            split: MacroSplit(proteinPercentage: 0.30, carbsPercentage: 0.40, fatPercentage: 0.30)
        )

        XCTAssertEqual(profile.targetDailyCalories, 1678.5, accuracy: 0.01)
        XCTAssertEqual(profile.targetProteinGrams, 125.89, accuracy: 0.1)
        XCTAssertEqual(profile.targetCarbsGrams, 167.85, accuracy: 0.1)
        XCTAssertEqual(profile.targetFatGrams, 55.95, accuracy: 0.1)
        XCTAssertEqual(profile.targetWaterIntakeMl, 2450.0, accuracy: 0.01)
    }

    func testRecalculateGoalsWithGoalType() {
        let profile = UserProfile(
            age: 25,
            weightInKg: 60.0,
            heightInCm: 165.0,
            biologicalSex: "female",
            activityLevel: 1.55
        )

        // Female BMR = 1345.25, TDEE = 2085.1375
        // Deficit for weightLoss: -500 kcal -> 1585.1375 kcal
        CalorieCalculationEngine.recalculateGoals(
            for: profile,
            goal: .weightLoss
        )

        XCTAssertEqual(profile.targetDailyCalories, 1585.14, accuracy: 0.1)
    }

    func testEdgeCaseMinimumCaloriesSafetyFloor() {
        let profile = UserProfile(
            age: 80,
            weightInKg: 35.0,
            heightInCm: 140.0,
            biologicalSex: "female",
            activityLevel: 1.0
        )
        // With extreme deficit, calories shouldn't drop below safety floor (e.g., 1000 or 1200 kcal minimum)
        CalorieCalculationEngine.recalculateGoals(
            for: profile,
            calorieAdjustment: -1500.0
        )
        XCTAssertGreaterThanOrEqual(profile.targetDailyCalories, 1000.0)
    }

    // MARK: - Boundary & Edge Case Tests

    func testBiologicalSexBoundaryValuesAndFallbacks() {
        // Unknown/invalid string should fallback gracefully (defaults to male formula in engine)
        let unknownBMR = CalorieCalculationEngine.calculateBMR(
            weightInKg: 70.0,
            heightInCm: 175.0,
            age: 30,
            biologicalSex: "other"
        )
        XCTAssertEqual(unknownBMR, 1648.75, accuracy: 0.01)

        // Case-insensitive checks
        let uppercaseBMR = CalorieCalculationEngine.calculateBMR(
            weightInKg: 60.0,
            heightInCm: 165.0,
            age: 25,
            biologicalSex: "FEMALE"
        )
        XCTAssertEqual(uppercaseBMR, 1345.25, accuracy: 0.01)
    }

    func testExtremeBodyMetricsCalculations() {
        // Extreme heavyweight & tall (e.g. 200kg, 220cm, 20yo male)
        let highBMR = CalorieCalculationEngine.calculateBMR(
            weightInKg: 200.0,
            heightInCm: 220.0,
            age: 20,
            biologicalSex: .male
        )
        // (10 * 200) + (6.25 * 220) - (5 * 20) + 5 = 2000 + 1375 - 100 + 5 = 3280
        XCTAssertEqual(highBMR, 3280.0, accuracy: 0.01)

        // Extreme light/short (e.g. 35kg, 130cm, 75yo female)
        let lowBMR = CalorieCalculationEngine.calculateBMR(
            weightInKg: 35.0,
            heightInCm: 130.0,
            age: 75,
            biologicalSex: .female
        )
        // (10 * 35) + (6.25 * 130) - (5 * 75) - 161 = 350 + 812.5 - 375 - 161 = 626.5
        XCTAssertEqual(lowBMR, 626.5, accuracy: 0.01)
    }

    func testMacroSplitPercentagesAutoNormalization() {
        // When percentages sum up to 100 in whole numbers (e.g. 40, 40, 20)
        let splitWhole = MacroSplit(proteinPercentage: 40, carbsPercentage: 40, fatPercentage: 20)
        let targets = CalorieCalculationEngine.calculateMacroTargets(totalCalories: 2000, split: splitWhole)
        XCTAssertEqual(targets.proteinGrams, 200.0, accuracy: 0.01)
        XCTAssertEqual(targets.carbsGrams, 200.0, accuracy: 0.01)
        XCTAssertEqual(targets.fatGrams, 44.44, accuracy: 0.1)

        // When percentages sum up to 1.0 in decimals (0.4, 0.4, 0.2)
        let splitDecimal = MacroSplit(proteinPercentage: 0.4, carbsPercentage: 0.4, fatPercentage: 0.2)
        let targetsDecimal = CalorieCalculationEngine.calculateMacroTargets(totalCalories: 2000, split: splitDecimal)
        XCTAssertEqual(targetsDecimal.proteinGrams, 200.0, accuracy: 0.01)
        XCTAssertEqual(targetsDecimal.carbsGrams, 200.0, accuracy: 0.01)
        XCTAssertEqual(targetsDecimal.fatGrams, 44.44, accuracy: 0.1)
    }
}
