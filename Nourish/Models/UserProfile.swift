import Foundation
import SwiftData

@Model
final class UserProfile {
    var age: Int
    var weightInKg: Double
    var heightInCm: Double
    var biologicalSex: String // "male" or "female"
    var activityLevel: Double // multiplier

    // Goals
    var targetDailyCalories: Double
    var targetProteinGrams: Double
    var targetCarbsGrams: Double
    var targetFatGrams: Double
    var targetWaterIntakeMl: Double

    var updatedAt: Date

    init(age: Int = 30,
         weightInKg: Double = 70.0,
         heightInCm: Double = 175.0,
         biologicalSex: String = "male",
         activityLevel: Double = 1.2,
         targetDailyCalories: Double = 2000.0,
         targetProteinGrams: Double = 150.0,
         targetCarbsGrams: Double = 200.0,
         targetFatGrams: Double = 65.0,
         targetWaterIntakeMl: Double = 2500.0,
         updatedAt: Date = Date()) {
        self.age = age
        self.weightInKg = weightInKg
        self.heightInCm = heightInCm
        self.biologicalSex = biologicalSex
        self.activityLevel = activityLevel
        self.targetDailyCalories = targetDailyCalories
        self.targetProteinGrams = targetProteinGrams
        self.targetCarbsGrams = targetCarbsGrams
        self.targetFatGrams = targetFatGrams
        self.targetWaterIntakeMl = targetWaterIntakeMl
        self.updatedAt = updatedAt
    }
}
