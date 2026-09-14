import Foundation
import HealthKit

// MARK: - HealthKit Errors

enum HealthKitError: Error, LocalizedError, Equatable {
    case notAvailable
    case dataTypeNotAvailable(String)
    case queryFailed(String)
    case authorizationDenied
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device."
        case .dataTypeNotAvailable(let type):
            return "HealthKit data type '\(type)' is not available."
        case .queryFailed(let reason):
            return "HealthKit query failed: \(reason)"
        case .authorizationDenied:
            return "HealthKit authorization was denied."
        case .saveFailed(let reason):
            return "Failed to save data to HealthKit: \(reason)"
        }
    }
}

// MARK: - HealthStoreProtocol for Dependency Injection

protocol HealthStoreProtocol: AnyObject, Sendable {
    var isHealthDataAvailable: Bool { get }
    func requestAuthorization(toShare typesToShare: Set<HKSampleType>, read typesToRead: Set<HKObjectType>) async throws
    func save(_ objects: [HKObject]) async throws
    func fetchSumQuantity(for type: HKQuantityType, predicate: NSPredicate) async throws -> Double?
}

// MARK: - HKHealthStore Conformance

extension HKHealthStore: HealthStoreProtocol {
    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func fetchSumQuantity(for type: HKQuantityType, predicate: NSPredicate) async throws -> Double? {
        guard isHealthDataAvailable else {
            throw HealthKitError.notAvailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let statistics = statistics, let sum = statistics.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }

                let unit: HKUnit
                if type.identifier == HKQuantityTypeIdentifier.stepCount.rawValue {
                    unit = .count()
                } else if type.identifier == HKQuantityTypeIdentifier.activeEnergyBurned.rawValue {
                    unit = .kilocalorie()
                } else if type.identifier == HKQuantityTypeIdentifier.dietaryWater.rawValue {
                    unit = .liter()
                } else if type.identifier == HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue {
                    unit = .kilocalorie()
                } else {
                    unit = .gram()
                }

                continuation.resume(returning: sum.doubleValue(for: unit))
            }
            self.execute(query)
        }
    }
}

// MARK: - HealthKitServiceProtocol

protocol HealthKitServiceProtocol: AnyObject, Sendable {
    var isAvailable: Bool { get }
    func requestAuthorization() async throws
    func fetchDailyBurnedEnergyAndSteps(for date: Date) async throws -> (activeEnergyBurnedKcal: Double, steps: Int)
    func fetchDailyBurnedEnergyAndSteps() async throws -> (activeEnergyBurnedKcal: Double, steps: Int)
    func exportFoodEntry(calories: Double, protein: Double, carbs: Double, fat: Double, date: Date, foodName: String?) async throws
    func exportFoodEntry(calories: Double, protein: Double, carbs: Double, fat: Double, date: Date) async throws
    func exportFoodEntry(calories: Double, protein: Double, carbs: Double, fat: Double) async throws
    func exportFoodEntry(_ foodItem: FoodItem) async throws
    func exportWater(liters: Double, date: Date) async throws
    func exportWater(liters: Double) async throws
    func exportWater(milliliters: Double, date: Date) async throws
    func exportWater(milliliters: Double) async throws
}

// MARK: - Default Protocol Implementations

extension HealthKitServiceProtocol {
    func fetchDailyBurnedEnergyAndSteps() async throws -> (activeEnergyBurnedKcal: Double, steps: Int) {
        try await fetchDailyBurnedEnergyAndSteps(for: Date())
    }

    func exportFoodEntry(calories: Double, protein: Double, carbs: Double, fat: Double, date: Date) async throws {
        try await exportFoodEntry(calories: calories, protein: protein, carbs: carbs, fat: fat, date: date, foodName: nil)
    }

    func exportFoodEntry(calories: Double, protein: Double, carbs: Double, fat: Double) async throws {
        try await exportFoodEntry(calories: calories, protein: protein, carbs: carbs, fat: fat, date: Date(), foodName: nil)
    }

    func exportFoodEntry(_ foodItem: FoodItem) async throws {
        try await exportFoodEntry(
            calories: foodItem.calories,
            protein: foodItem.proteinGrams,
            carbs: foodItem.carbsGrams,
            fat: foodItem.fatGrams,
            date: foodItem.timestamp,
            foodName: foodItem.name
        )
    }

    func exportWater(liters: Double) async throws {
        try await exportWater(liters: liters, date: Date())
    }

    func exportWater(milliliters: Double, date: Date) async throws {
        try await exportWater(liters: milliliters / 1000.0, date: date)
    }

    func exportWater(milliliters: Double) async throws {
        try await exportWater(liters: milliliters / 1000.0, date: Date())
    }
}

// MARK: - HealthKitService Implementation

final class HealthKitService: HealthKitServiceProtocol, @unchecked Sendable {
    static let shared = HealthKitService()

    private let healthStore: HealthStoreProtocol

    init(healthStore: HealthStoreProtocol = HKHealthStore()) {
        self.healthStore = healthStore
    }

    var isAvailable: Bool {
        healthStore.isHealthDataAvailable
    }

    func requestAuthorization() async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.dietaryEnergyConsumed),
            HKQuantityType(.dietaryProtein),
            HKQuantityType(.dietaryCarbohydrates),
            HKQuantityType(.dietaryFatTotal),
            HKQuantityType(.dietaryWater),
            HKObjectType.workoutType()
        ]

        let shareTypes: Set<HKSampleType> = [
            HKQuantityType(.dietaryEnergyConsumed),
            HKQuantityType(.dietaryProtein),
            HKQuantityType(.dietaryCarbohydrates),
            HKQuantityType(.dietaryFatTotal),
            HKQuantityType(.dietaryWater)
        ]

        do {
            try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
        } catch {
            throw HealthKitError.queryFailed(error.localizedDescription)
        }
    }

    func fetchDailyBurnedEnergyAndSteps(for date: Date = Date()) async throws -> (activeEnergyBurnedKcal: Double, steps: Int) {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw HealthKitError.queryFailed("Could not calculate end of day")
        }

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        async let stepsValue = healthStore.fetchSumQuantity(for: HKQuantityType(.stepCount), predicate: predicate)
        async let activeEnergyValue = healthStore.fetchSumQuantity(for: HKQuantityType(.activeEnergyBurned), predicate: predicate)

        do {
            let (stepsSum, energySum) = try await (stepsValue, activeEnergyValue)
            let steps = Int(stepsSum ?? 0)
            let energy = energySum ?? 0.0
            return (activeEnergyBurnedKcal: energy, steps: steps)
        } catch {
            throw HealthKitError.queryFailed(error.localizedDescription)
        }
    }

    func exportFoodEntry(
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        date: Date = Date(),
        foodName: String? = nil
    ) async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        var metadata: [String: Any]? = nil
        if let foodName = foodName, !foodName.isEmpty {
            metadata = [HKMetadataKeyFoodType: foodName]
        }

        var samples: [HKQuantitySample] = []

        if calories > 0 || (protein == 0 && carbs == 0 && fat == 0) {
            let energyType = HKQuantityType(.dietaryEnergyConsumed)
            let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
            let sample = HKQuantitySample(type: energyType, quantity: energyQuantity, start: date, end: date, metadata: metadata)
            samples.append(sample)
        }

        if protein > 0 {
            let proteinType = HKQuantityType(.dietaryProtein)
            let proteinQuantity = HKQuantity(unit: .gram(), doubleValue: protein)
            let sample = HKQuantitySample(type: proteinType, quantity: proteinQuantity, start: date, end: date, metadata: metadata)
            samples.append(sample)
        }

        if carbs > 0 {
            let carbsType = HKQuantityType(.dietaryCarbohydrates)
            let carbsQuantity = HKQuantity(unit: .gram(), doubleValue: carbs)
            let sample = HKQuantitySample(type: carbsType, quantity: carbsQuantity, start: date, end: date, metadata: metadata)
            samples.append(sample)
        }

        if fat > 0 {
            let fatType = HKQuantityType(.dietaryFatTotal)
            let fatQuantity = HKQuantity(unit: .gram(), doubleValue: fat)
            let sample = HKQuantitySample(type: fatType, quantity: fatQuantity, start: date, end: date, metadata: metadata)
            samples.append(sample)
        }

        guard !samples.isEmpty else { return }

        do {
            try await healthStore.save(samples)
        } catch {
            throw HealthKitError.saveFailed(error.localizedDescription)
        }
    }

    func exportWater(liters: Double, date: Date = Date()) async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        let waterType = HKQuantityType(.dietaryWater)
        let quantity = HKQuantity(unit: .liter(), doubleValue: liters)
        let sample = HKQuantitySample(type: waterType, quantity: quantity, start: date, end: date)

        do {
            try await healthStore.save([sample])
        } catch {
            throw HealthKitError.saveFailed(error.localizedDescription)
        }
    }
}

// MARK: - Mocks for Testing and Previews

final class MockHealthStore: HealthStoreProtocol, @unchecked Sendable {
    var isHealthDataAvailableStub: Bool = true
    var requestAuthorizationCalled: Bool = false
    var requestedShareTypes: Set<HKSampleType> = []
    var requestedReadTypes: Set<HKObjectType> = []
    var savedObjects: [HKObject] = []
    var sumQuantities: [String: Double] = [:]
    var shouldThrowError: Error? = nil

    init(isHealthDataAvailable: Bool = true) {
        self.isHealthDataAvailableStub = isHealthDataAvailable
    }

    var isHealthDataAvailable: Bool {
        isHealthDataAvailableStub
    }

    func requestAuthorization(toShare typesToShare: Set<HKSampleType>, read typesToRead: Set<HKObjectType>) async throws {
        if let error = shouldThrowError {
            throw error
        }
        guard isHealthDataAvailableStub else {
            throw HealthKitError.notAvailable
        }
        requestAuthorizationCalled = true
        requestedShareTypes = typesToShare
        requestedReadTypes = typesToRead
    }

    func save(_ objects: [HKObject]) async throws {
        if let error = shouldThrowError {
            throw error
        }
        guard isHealthDataAvailableStub else {
            throw HealthKitError.notAvailable
        }
        savedObjects.append(contentsOf: objects)
    }

    func fetchSumQuantity(for type: HKQuantityType, predicate: NSPredicate) async throws -> Double? {
        if let error = shouldThrowError {
            throw error
        }
        guard isHealthDataAvailableStub else {
            throw HealthKitError.notAvailable
        }
        return sumQuantities[type.identifier]
    }
}

final class MockHealthKitService: HealthKitServiceProtocol, @unchecked Sendable {
    var isAvailableStub: Bool = true
    var requestAuthorizationCalled: Bool = false
    var mockSteps: Int = 0
    var mockActiveEnergy: Double = 0.0
    var shouldThrowError: Error? = nil

    struct ExportedFoodEntry: Equatable {
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
        let date: Date
        let foodName: String?

        init(calories: Double, protein: Double, carbs: Double, fat: Double, date: Date, foodName: String?) {
            self.calories = calories
            self.protein = protein
            self.carbs = carbs
            self.fat = fat
            self.date = date
            self.foodName = foodName
        }
    }

    struct ExportedWaterEntry: Equatable {
        let liters: Double
        let date: Date

        init(liters: Double, date: Date) {
            self.liters = liters
            self.date = date
        }
    }

    var exportedFoodEntries: [ExportedFoodEntry] = []
    var exportedWaterEntries: [ExportedWaterEntry] = []

    init(isAvailable: Bool = true) {
        self.isAvailableStub = isAvailable
    }

    var isAvailable: Bool {
        isAvailableStub
    }

    func requestAuthorization() async throws {
        if let error = shouldThrowError {
            throw error
        }
        guard isAvailableStub else {
            throw HealthKitError.notAvailable
        }
        requestAuthorizationCalled = true
    }

    func fetchDailyBurnedEnergyAndSteps(for date: Date) async throws -> (activeEnergyBurnedKcal: Double, steps: Int) {
        if let error = shouldThrowError {
            throw error
        }
        guard isAvailableStub else {
            throw HealthKitError.notAvailable
        }
        return (activeEnergyBurnedKcal: mockActiveEnergy, steps: mockSteps)
    }

    func exportFoodEntry(
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        date: Date,
        foodName: String?
    ) async throws {
        if let error = shouldThrowError {
            throw error
        }
        guard isAvailableStub else {
            throw HealthKitError.notAvailable
        }
        exportedFoodEntries.append(
            ExportedFoodEntry(
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                date: date,
                foodName: foodName
            )
        )
    }

    func exportWater(liters: Double, date: Date) async throws {
        if let error = shouldThrowError {
            throw error
        }
        guard isAvailableStub else {
            throw HealthKitError.notAvailable
        }
        exportedWaterEntries.append(
            ExportedWaterEntry(liters: liters, date: date)
        )
    }
}
