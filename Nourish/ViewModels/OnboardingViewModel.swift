import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class OnboardingViewModel {
    enum OnboardingStep: Int, CaseIterable, Identifiable {
        case welcome = 0
        case biometrics
        case activity
        case goal
        case pace
        case macroSplit
        case summary

        var id: Int { self.rawValue }
    }

    var currentStep: OnboardingStep = .welcome

    // Biometrics inputs
    var age: Int = 28
    var biologicalSex: BiologicalSex = .male
    var heightCm: Double = 175.0
    var weightKg: Double = 75.0

    // Activity & Goals
    var activityLevel: ActivityLevel = .moderatelyActive
    var goalType: GoalType = .weightLoss
    var weeklyWeightChangeKg: Double = -0.5

    // Macro Split (percentages 0-100)
    var proteinPercentage: Double = 30.0
    var carbsPercentage: Double = 40.0
    var fatPercentage: Double = 30.0

    // Computed values
    var calculatedBMR: Double {
        CalorieCalculationEngine.calculateBMR(weightInKg: weightKg, heightInCm: heightCm, age: age, biologicalSex: biologicalSex)
    }

    var calculatedTDEE: Double {
        CalorieCalculationEngine.calculateTDEE(bmr: calculatedBMR, activityLevel: activityLevel)
    }

    var calculatedDailyCalories: Double {
        // Daily calorie deficit/surplus: 1 kg of weight change is approx 7700 kcal
        let effectiveChange = goalType == .weightLoss ? -abs(weeklyWeightChangeKg) : goalType == .weightGain ? abs(weeklyWeightChangeKg) : 0.0
        let dailyAdjustment = (effectiveChange * 7700.0) / 7.0

        let calories = calculatedTDEE + dailyAdjustment

        // Safety floor
        return max(1200.0, calories)
    }

    var calculatedMacroTargets: (protein: Double, carbs: Double, fat: Double) {
        let targets = CalorieCalculationEngine.calculateMacroTargets(
            totalCalories: calculatedDailyCalories,
            proteinPercentage: proteinPercentage / 100.0,
            carbsPercentage: carbsPercentage / 100.0,
            fatPercentage: fatPercentage / 100.0
        )
        return (protein: targets.proteinGrams, carbs: targets.carbsGrams, fat: targets.fatGrams)
    }

    var waterIntakeLiters: Double {
        CalorieCalculationEngine.calculateWaterIntake(weightInKg: weightKg) / 1000.0
    }

    var canProceed: Bool {
        guard age >= 13 && age <= 100 else { return false }
        guard heightCm > 50 && heightCm < 300 else { return false }
        guard weightKg > 20 && weightKg < 500 else { return false }

        let totalMacros = proteinPercentage + carbsPercentage + fatPercentage
        guard abs(totalMacros - 100.0) < 1.0 else { return false }

        return true
    }

    func nextStep() {
        guard canProceed else { return }
        if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        }
    }

    func previousStep() {
        if let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) {
            currentStep = prev
        }
    }

    func createUserProfile() -> UserProfile {
        let targets = calculatedMacroTargets

        return UserProfile(
            age: age,
            weightInKg: weightKg,
            heightInCm: heightCm,
            biologicalSex: biologicalSex.rawValue,
            activityLevel: activityLevel.rawValue,
            targetDailyCalories: calculatedDailyCalories,
            targetProteinGrams: targets.protein,
            targetCarbsGrams: targets.carbs,
            targetFatGrams: targets.fat,
            targetWaterIntakeMl: waterIntakeLiters * 1000.0,
            updatedAt: Date()
        )
    }

    func saveToSwiftData(context: ModelContext) {
        let profile = createUserProfile()
        context.insert(profile)
        do {
            try context.save()
        } catch {
            print("Failed to save profile: \(error)")
        }
    }
}
