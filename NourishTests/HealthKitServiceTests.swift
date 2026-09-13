import XCTest
import HealthKit
@testable import Nourish

final class HealthKitServiceTests: XCTestCase {

    var mockStore: MockHealthStore!
    var service: HealthKitService!

    override func setUp() {
        super.setUp()
        mockStore = MockHealthStore()
        service = HealthKitService(healthStore: mockStore)
    }

    override func tearDown() {
        mockStore = nil
        service = nil
        super.tearDown()
    }

    // MARK: - Authorization Tests

    func testAuthorizationRequestsAllRequiredTypes() async throws {
        // Given HealthKit is available
        mockStore.isHealthDataAvailableStub = true

        // When requesting authorization
        try await service.requestAuthorization()

        // Then verify request was made
        XCTAssertTrue(mockStore.requestAuthorizationCalled)

        // Verify read types
        let expectedReadIdentifiers: Set<HKQuantityTypeIdentifier> = [
            .stepCount,
            .activeEnergyBurned,
            .dietaryEnergyConsumed,
            .dietaryProtein,
            .dietaryCarbohydrates,
            .dietaryFatTotal,
            .dietaryWater
        ]
        let requestedReadIdentifiers = Set(mockStore.requestedReadTypes.compactMap { $0 as? HKQuantityType }.map { HKQuantityTypeIdentifier(rawValue: $0.identifier) })
        XCTAssertEqual(requestedReadIdentifiers, expectedReadIdentifiers)

        // Verify share types
        let expectedShareIdentifiers: Set<HKQuantityTypeIdentifier> = [
            .dietaryEnergyConsumed,
            .dietaryProtein,
            .dietaryCarbohydrates,
            .dietaryFatTotal,
            .dietaryWater
        ]
        let requestedShareIdentifiers = Set(mockStore.requestedShareTypes.compactMap { $0 as? HKQuantityType }.map { HKQuantityTypeIdentifier(rawValue: $0.identifier) })
        XCTAssertTrue(expectedShareIdentifiers.isSubset(of: requestedShareIdentifiers))
    }

    func testAuthorizationWhenHealthKitUnavailable() async {
        // Given HealthKit is NOT available
        mockStore.isHealthDataAvailableStub = false

        // When / Then
        do {
            try await service.requestAuthorization()
            XCTFail("Expected requestAuthorization to throw when HealthKit is unavailable")
        } catch let error as HealthKitError {
            XCTAssertEqual(error, .notAvailable)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Fetch Daily Burned Energy & Steps Tests

    func testFetchDailyBurnedEnergyAndStepsSuccess() async throws {
        // Given mock data
        mockStore.isHealthDataAvailableStub = true
        mockStore.sumQuantities[HKQuantityTypeIdentifier.stepCount.rawValue] = 8542.0
        mockStore.sumQuantities[HKQuantityTypeIdentifier.activeEnergyBurned.rawValue] = 450.5

        // When
        let result = try await service.fetchDailyBurnedEnergyAndSteps(for: Date())

        // Then
        XCTAssertEqual(result.steps, 8542)
        XCTAssertEqual(result.activeEnergyBurnedKcal, 450.5, accuracy: 0.01)
    }

    func testFetchDailyBurnedEnergyAndStepsWhenNoData() async throws {
        // Given no data recorded
        mockStore.isHealthDataAvailableStub = true
        mockStore.sumQuantities = [:]

        // When
        let result = try await service.fetchDailyBurnedEnergyAndSteps(for: Date())

        // Then
        XCTAssertEqual(result.steps, 0)
        XCTAssertEqual(result.activeEnergyBurnedKcal, 0.0, accuracy: 0.01)
    }

    func testFetchDailyBurnedEnergyAndStepsWhenUnavailable() async {
        // Given HealthKit is NOT available
        mockStore.isHealthDataAvailableStub = false

        // When / Then
        do {
            _ = try await service.fetchDailyBurnedEnergyAndSteps(for: Date())
            XCTFail("Expected fetch to throw when HealthKit is unavailable")
        } catch let error as HealthKitError {
            XCTAssertEqual(error, .notAvailable)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Export Food Entry Tests

    func testExportFoodEntrySavesAllMacroSamples() async throws {
        // Given
        mockStore.isHealthDataAvailableStub = true
        let date = Date()

        // When
        try await service.exportFoodEntry(
            calories: 500,
            protein: 30,
            carbs: 60,
            fat: 15,
            date: date
        )

        // Then
        XCTAssertEqual(mockStore.savedObjects.count, 4)

        let savedQuantitySamples = mockStore.savedObjects.compactMap { $0 as? HKQuantitySample }
        XCTAssertEqual(savedQuantitySamples.count, 4)

        // Verify Calories
        let energySample = try XCTUnwrap(savedQuantitySamples.first { $0.quantityType.identifier == HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue })
        XCTAssertEqual(energySample.quantity.doubleValue(for: .kilocalorie()), 500, accuracy: 0.01)

        // Verify Protein
        let proteinSample = try XCTUnwrap(savedQuantitySamples.first { $0.quantityType.identifier == HKQuantityTypeIdentifier.dietaryProtein.rawValue })
        XCTAssertEqual(proteinSample.quantity.doubleValue(for: .gram()), 30, accuracy: 0.01)

        // Verify Carbs
        let carbsSample = try XCTUnwrap(savedQuantitySamples.first { $0.quantityType.identifier == HKQuantityTypeIdentifier.dietaryCarbohydrates.rawValue })
        XCTAssertEqual(carbsSample.quantity.doubleValue(for: .gram()), 60, accuracy: 0.01)

        // Verify Fat
        let fatSample = try XCTUnwrap(savedQuantitySamples.first { $0.quantityType.identifier == HKQuantityTypeIdentifier.dietaryFatTotal.rawValue })
        XCTAssertEqual(fatSample.quantity.doubleValue(for: .gram()), 15, accuracy: 0.01)
    }

    func testExportFoodItem() async throws {
        // Given
        mockStore.isHealthDataAvailableStub = true
        let item = FoodItem(
            name: "Oatmeal with Berries",
            calories: 320,
            proteinGrams: 12,
            carbsGrams: 54,
            fatGrams: 6,
            mealType: .breakfast
        )

        // When
        try await service.exportFoodEntry(item)

        // Then
        XCTAssertEqual(mockStore.savedObjects.count, 4)
        let savedQuantitySamples = mockStore.savedObjects.compactMap { $0 as? HKQuantitySample }
        let energySample = try XCTUnwrap(savedQuantitySamples.first { $0.quantityType.identifier == HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue })
        XCTAssertEqual(energySample.quantity.doubleValue(for: .kilocalorie()), 320, accuracy: 0.01)
        XCTAssertEqual(energySample.metadata?[HKMetadataKeyFoodType] as? String, "Oatmeal with Berries")
    }

    func testExportFoodEntryZeroMacrosOnlySavesCalories() async throws {
        // Given
        mockStore.isHealthDataAvailableStub = true

        // When
        try await service.exportFoodEntry(
            calories: 100,
            protein: 0,
            carbs: 0,
            fat: 0
        )

        // Then only 1 sample (calories) should be saved
        XCTAssertEqual(mockStore.savedObjects.count, 1)
        let energySample = try XCTUnwrap(mockStore.savedObjects.first as? HKQuantitySample)
        XCTAssertEqual(energySample.quantityType.identifier, HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue)
        XCTAssertEqual(energySample.quantity.doubleValue(for: .kilocalorie()), 100, accuracy: 0.01)
    }

    // MARK: - Export Water Tests

    func testExportWaterInLiters() async throws {
        // Given
        mockStore.isHealthDataAvailableStub = true
        let date = Date()

        // When
        try await service.exportWater(liters: 0.75, date: date)

        // Then
        XCTAssertEqual(mockStore.savedObjects.count, 1)
        guard let waterSample = mockStore.savedObjects.first as? HKQuantitySample else {
            XCTFail("Expected HKQuantitySample")
            return
        }
        XCTAssertEqual(waterSample.quantityType.identifier, HKQuantityTypeIdentifier.dietaryWater.rawValue)
        XCTAssertEqual(waterSample.quantity.doubleValue(for: .liter()), 0.75, accuracy: 0.001)
    }

    func testExportWaterInMilliliters() async throws {
        // Given
        mockStore.isHealthDataAvailableStub = true

        // When
        try await service.exportWater(milliliters: 500)

        // Then
        XCTAssertEqual(mockStore.savedObjects.count, 1)
        guard let waterSample = mockStore.savedObjects.first as? HKQuantitySample else {
            XCTFail("Expected HKQuantitySample")
            return
        }
        XCTAssertEqual(waterSample.quantityType.identifier, HKQuantityTypeIdentifier.dietaryWater.rawValue)
        XCTAssertEqual(waterSample.quantity.doubleValue(for: .liter()), 0.5, accuracy: 0.001)
    }

    func testExportWaterWhenUnavailable() async {
        // Given HealthKit is NOT available
        mockStore.isHealthDataAvailableStub = false

        // When / Then
        do {
            try await service.exportWater(liters: 1.0)
            XCTFail("Expected exportWater to throw when HealthKit is unavailable")
        } catch let error as HealthKitError {
            XCTAssertEqual(error, .notAvailable)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Mock Service Protocol Conformance Test

    func testMockHealthKitServiceProtocolImplementation() async throws {
        // Given a mock service conforming to HealthKitServiceProtocol
        let mockService = MockHealthKitService()
        mockService.mockSteps = 10000
        mockService.mockActiveEnergy = 600.0

        // When
        try await mockService.requestAuthorization()
        let daily = try await mockService.fetchDailyBurnedEnergyAndSteps()
        try await mockService.exportFoodEntry(calories: 200, protein: 10, carbs: 20, fat: 5)
        try await mockService.exportWater(liters: 1.5)

        // Then
        XCTAssertTrue(mockService.requestAuthorizationCalled)
        XCTAssertEqual(daily.steps, 10000)
        XCTAssertEqual(daily.activeEnergyBurnedKcal, 600.0)
        XCTAssertEqual(mockService.exportedFoodEntries.count, 1)
        XCTAssertEqual(mockService.exportedWaterEntries.count, 1)
    }
}
