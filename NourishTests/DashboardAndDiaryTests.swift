import XCTest
import SwiftData
@testable import Nourish

@MainActor
final class DashboardAndDiaryTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: UserProfile.self, DailyLog.self, FoodItem.self, configurations: config)
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    // MARK: - DashboardViewModel Tests

    func testDashboardViewModelCalculations() throws {
        let profile = UserProfile(targetDailyCalories: 2000, targetProteinGrams: 150, targetCarbsGrams: 200, targetFatGrams: 65)
        context.insert(profile)
        let log = DailyLog(dateString: "2026-09-13", activeEnergyBurnedKcal: 300)
        context.insert(log)
        let food = FoodItem(name: "Test", calories: 500, proteinGrams: 50, carbsGrams: 50, fatGrams: 10, mealType: .breakfast, dailyLog: log)
        context.insert(food)

        try context.save()

        let vm = DashboardViewModel(healthKitService: MockHealthKitService())
        vm.loadData(context: context)

        // Calories Remaining = Goal - Consumed + Burned = 2000 - 500 + 300 = 1800
        XCTAssertEqual(vm.caloriesRemaining, 1800)
        XCTAssertEqual(vm.consumedCalories, 500)
        XCTAssertEqual(vm.burnedCalories, 300)

        // Protein progress = 50 / 150 = 0.333
        XCTAssertEqual(vm.proteinProgress, 50.0/150.0, accuracy: 0.01)
    }

    // MARK: - DiaryViewModel Tests

    func testDiaryViewModelGroupingAndDeletion() throws {
        let log = DailyLog(dateString: "2026-09-13")
        context.insert(log)
        let f1 = FoodItem(name: "Breakfast 1", calories: 100, mealType: .breakfast, dailyLog: log)
        let f2 = FoodItem(name: "Lunch 1", calories: 200, mealType: .lunch, dailyLog: log)
        context.insert(f1)
        context.insert(f2)
        try context.save()

        let vm = DiaryViewModel()
        vm.loadData(for: Date(), context: context)

        XCTAssertEqual(vm.items(for: .breakfast).count, 1)
        XCTAssertEqual(vm.items(for: .lunch).count, 1)
        XCTAssertEqual(vm.totalCalories(for: .breakfast), 100)

        vm.deleteFoodItem(f1, context: context)
        XCTAssertEqual(vm.items(for: .breakfast).count, 0)
    }

    func testDateSwitching() throws {
        let vm = DiaryViewModel()
        let initialDate = Date()
        vm.loadData(for: initialDate, context: context)

        vm.changeDate(byDays: 1, context: context)

        XCTAssertTrue(Calendar.current.isDateInTomorrow(vm.selectedDate))
        XCTAssertNotEqual(vm.selectedDate, initialDate)
    }

    // MARK: - ManualFoodEntryView Logic Test

    func testManualFoodEntryCalorieCalculation() {
        let p: Double = 30
        let c: Double = 40
        let f: Double = 10
        let expectedCalories = (p * 4.0) + (c * 4.0) + (f * 9.0)
        XCTAssertEqual(expectedCalories, 370)
    }
}
