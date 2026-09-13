import Foundation
import Nourish // For UserProfile when using types defined in Nourish (though UserProfile is in Models)

// MARK: - Supporting Types

enum BiologicalSex: String, CaseIterable, Codable {
    case male = "male"
    case female = "female"
}

enum ActivityLevel: Double, CaseIterable, Codable {
    case sedentary = 1.2
    case lightlyActive = 1.375
    case moderatelyActive = 1.55
    case veryActive = 1.725
    case extremelyActive = 1.9
}

enum GoalType: String, CaseIterable, Codable {
    case weightLoss
    case maintain
    case weightGain
}

struct MacroSplit: Equatable, Codable {
    var proteinPercentage: Double // 0.0 to 1.0 (or > 1 interpret as %)
    var carbsPercentage: Double
    var fatPercentage: Double

    static let defaultSplit = MacroSplit(proteinPercentage: 0.30, carbsPercentage: 0.40, fatPercentage: 0.30)

    init(proteinPercentage: Double, carbsPercentage: Double, fatPercentage: Double) {
        // Normalize if inputs are percentages (e.g. 30, 40, 30 -> total 100)
        let total = proteinPercentage + carbsPercentage + fatPercentage
        if total > 1.5 { // Assuming > 1.0 means percentages 0-100
            self.proteinPercentage = proteinPercentage / 100.0
            self.carbsPercentage = carbsPercentage / 100.0
            self.fatPercentage = fatPercentage / 100.0
        } else {
            self.proteinPercentage = proteinPercentage
            self.carbsPercentage = carbsPercentage
            self.fatPercentage = fatPercentage
        }
    }
}

struct MacroTargets: Equatable, Codable {
    let calories: Double
    let proteinGrams: Double
    let carbsGrams: Double
    let fatGrams: Double
}

struct CalorieCalculationEngine {

    // MARK: - BMR

    static func calculateBMR(weightInKg: Double, heightInCm: Double, age: Int, biologicalSex: BiologicalSex) -> Double {
        return calculateBMR(weightInKg: weightInKg, heightInCm: heightInCm, age: age, biologicalSex: biologicalSex.rawValue)
    }

    static func calculateBMR(weightInKg: Double, heightInCm: Double, age: Int, biologicalSex: String) -> Double {
        let genderFactor = biologicalSex.lowercased() == "female" ? -161.0 : 5.0
        return (10.0 * weightInKg) + (6.25 * heightInCm) - (5.0 * Double(age)) + genderFactor
    }

    static func calculateBMR(for userProfile: UserProfile) -> Double {
        return calculateBMR(
            weightInKg: userProfile.weightInKg,
            heightInCm: userProfile.heightInCm,
            age: userProfile.age,
            biologicalSex: userProfile.biologicalSex
        )
    }

    // MARK: - TDEE

    static func calculateTDEE(bmr: Double, activityMultiplier: Double) -> Double {
        return bmr * activityMultiplier
    }

    static func calculateTDEE(bmr: Double, activityLevel: ActivityLevel) -> Double {
        return calculateTDEE(bmr: bmr, activityMultiplier: activityLevel.rawValue)
    }

    static func calculateTDEE(for userProfile: UserProfile) -> Double {
        let bmr = calculateBMR(for: userProfile)
        return calculateTDEE(bmr: bmr, activityMultiplier: userProfile.activityLevel)
    }

    // MARK: - Macros

    static func calculateMacroTargets(totalCalories: Double, proteinPercentage: Double = 0.30, carbsPercentage: Double = 0.40, fatPercentage: Double = 0.30) -> MacroTargets {
        let split = MacroSplit(proteinPercentage: proteinPercentage, carbsPercentage: carbsPercentage, fatPercentage: fatPercentage)
        return calculateMacroTargets(totalCalories: totalCalories, split: split)
    }

    static func calculateMacroTargets(totalCalories: Double, split: MacroSplit) -> MacroTargets {
        let proteinGrams = (totalCalories * split.proteinPercentage) / 4.0
        let carbsGrams = (totalCalories * split.carbsPercentage) / 4.0
        let fatGrams = (totalCalories * split.fatPercentage) / 9.0

        return MacroTargets(
            calories: totalCalories,
            proteinGrams: proteinGrams,
            carbsGrams: carbsGrams,
            fatGrams: fatGrams
        )
    }

    // MARK: - Utilities

    static func calculateWaterIntake(weightInKg: Double) -> Double {
        // Standard recommendation approx 35ml per kg bodyweight
        return weightInKg * 35.0
    }

    // MARK: - Recalculate Goals

    static func recalculateGoals(
        for profile: UserProfile,
        calorieAdjustment: Double = 0.0,
        goal: GoalType? = nil,
        split: MacroSplit = .defaultSplit
    ) {
        let tdee = calculateTDEE(for: profile)

        let adjustment: Double
        if let goal = goal {
            switch goal {
            case .weightLoss: adjustment = -500.0
            case .maintain: adjustment = 0.0
            case .weightGain: adjustment = 300.0
            }
        } else {
            adjustment = calorieAdjustment
        }

        let targetCalories = max(1000.0, tdee + adjustment)

        let macros = calculateMacroTargets(totalCalories: targetCalories, split: split)

        profile.targetDailyCalories = targetCalories
        profile.targetProteinGrams = macros.proteinGrams
        profile.targetCarbsGrams = macros.carbsGrams
        profile.targetFatGrams = macros.fatGrams
        profile.targetWaterIntakeMl = calculateWaterIntake(weightInKg: profile.weightInKg)
        profile.updatedAt = Date()
    }
}
