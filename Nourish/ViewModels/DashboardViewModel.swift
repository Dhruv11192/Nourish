import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class DashboardViewModel {

    var userProfile: UserProfile?
    var todayLog: DailyLog?

    var steps: Int = 0

    var isLoading: Bool = false
    var error: Error?

    private let healthKitService: HealthKitServiceProtocol

    init(healthKitService: HealthKitServiceProtocol = HealthKitService.shared) {
        self.healthKitService = healthKitService
    }

    func loadData(context: ModelContext) {
        isLoading = true
        fetchUserProfile(context: context)
        fetchTodayLog(context: context)

        Task {
            await syncHealthKit(context: context)
            isLoading = false
        }
    }

    private func fetchUserProfile(context: ModelContext) {
        let descriptor = FetchDescriptor<UserProfile>()
        do {
            userProfile = try context.fetch(descriptor).first
        } catch {
            self.error = error
        }
    }

    private func fetchTodayLog(context: ModelContext) {
        let todayString = DateFormatter.yyyyMMdd.string(from: Date())

        let descriptor = FetchDescriptor<DailyLog>(predicate: #Predicate<DailyLog> { log in
            log.dateString == todayString
        })

        do {
            if let log = try context.fetch(descriptor).first {
                self.todayLog = log
            } else {
                let newLog = DailyLog(dateString: todayString)
                context.insert(newLog)
                try context.save()
                self.todayLog = newLog
            }
        } catch {
            self.error = error
        }
    }

    private func syncHealthKit(context: ModelContext) async {
        guard let todayLog = todayLog, healthKitService.isAvailable else { return }

        do {
            try await healthKitService.requestAuthorization()
            let data = try await healthKitService.fetchDailyBurnedEnergyAndSteps(for: Date())
            self.steps = data.steps
            todayLog.activeEnergyBurnedKcal = data.activeEnergyBurnedKcal
            try context.save()
        } catch {
            self.error = error
        }
    }

    var caloriesRemaining: Double {
        guard let profile = userProfile, let log = todayLog else { return 0 }
        let remaining = profile.targetDailyCalories - log.totalCalories + log.activeEnergyBurnedKcal
        return max(0, remaining)
    }

    var consumedCalories: Double {
        todayLog?.totalCalories ?? 0
    }

    var burnedCalories: Double {
        todayLog?.activeEnergyBurnedKcal ?? 0
    }

    var calorieGoal: Double {
        userProfile?.targetDailyCalories ?? 2000
    }

    var proteinProgress: Double {
        guard let profile = userProfile, let log = todayLog, profile.targetProteinGrams > 0 else { return 0 }
        return min(log.totalProtein / profile.targetProteinGrams, 1.0)
    }

    var carbsProgress: Double {
        guard let profile = userProfile, let log = todayLog, profile.targetCarbsGrams > 0 else { return 0 }
        return min(log.totalCarbs / profile.targetCarbsGrams, 1.0)
    }

    var fatProgress: Double {
        guard let profile = userProfile, let log = todayLog, profile.targetFatGrams > 0 else { return 0 }
        return min(log.totalFat / profile.targetFatGrams, 1.0)
    }

    var waterProgress: Double {
        guard let profile = userProfile, let log = todayLog, profile.targetWaterIntakeMl > 0 else { return 0 }
        return min(log.waterIntakeMl / profile.targetWaterIntakeMl, 1.0)
    }

    func addWater(amountMl: Double, context: ModelContext) {
        guard let log = todayLog else { return }
        log.waterIntakeMl += amountMl
        do {
            try context.save()

            Task {
                try? await healthKitService.exportWater(milliliters: amountMl, date: Date())
            }
        } catch {
            self.error = error
        }
    }
}

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
