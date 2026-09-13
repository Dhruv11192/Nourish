import XCTest
import SwiftData
@testable import Nourish

final class ModelTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        // Create an in-memory database for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: UserProfile.self, DailyLog.self, FoodItem.self, configurations: config)
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    func testMealTypeEncoding() throws {
        let type = MealType.breakfast
        XCTAssertEqual(type.rawValue, "breakfast")
    }

    func testUserProfileCreation() throws {
        let profile = UserProfile(age: 28, weightInKg: 80.0, heightInCm: 180.0, biologicalSex: "male")
        context.insert(profile)

        try context.save()
        let fetchDescriptor = FetchDescriptor<UserProfile>()
        let profiles = try context.fetch(fetchDescriptor)

        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.age, 28)
    }

    func testDailyLogAndFoodItems() throws {
        let log = DailyLog(dateString: "2026-09-13", waterIntakeMl: 500)
        context.insert(log)

        let food1 = FoodItem(name: "Oatmeal", calories: 150, mealType: .breakfast, dailyLog: log)
        let food2 = FoodItem(name: "Apple", calories: 95, mealType: .snack, dailyLog: log)

        context.insert(food1)
        context.insert(food2)

        try context.save()

        // Assert bi-directional relationship is correctly assigned via context
        XCTAssertEqual(log.foodItems.count, 2)
        XCTAssertEqual(log.totalCalories, 245)
    }
}
