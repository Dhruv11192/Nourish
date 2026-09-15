import Foundation
import SwiftData

@Model
class UserProfile {
    var name: String
    var weightKg: Double
    var heightCm: Double
    var age: Int
    var isMale: Bool
    var dailyCalorieGoal: Int = 2000

    init(name: String, weightKg: Double, heightCm: Double, age: Int, isMale: Bool) {
        self.name = name
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.age = age
        self.isMale = isMale
    }

    func calculateBMR() -> Double {
        // Mifflin-St Jeor Equation
        if isMale {
            return (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) + 5
        } else {
            return (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) - 161
        }
    }
}
