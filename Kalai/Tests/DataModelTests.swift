import XCTest
import SwiftData
@testable import Kalai

final class DataModelTests: XCTestCase {
    func testCalorieCalculation() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserProfile.self, configurations: config)
        let context = ModelContext(container)

        let user = UserProfile(name: "Tester", weightKg: 70.0, heightCm: 175.0, age: 25, isMale: true)
        context.insert(user)

        let bmr = user.calculateBMR()
        XCTAssertGreaterThan(bmr, 1500.0)
        XCTAssertEqual(bmr, 1673.75, accuracy: 0.01)
    }

    func testFemaleBMRCalculation() throws {
        let user = UserProfile(name: "TesterF", weightKg: 60.0, heightCm: 165.0, age: 30, isMale: false)
        let bmr = user.calculateBMR()
        XCTAssertEqual(bmr, 1320.25, accuracy: 0.01)
    }

    func testDailyDiaryTotalCalories() throws {
        let food1 = FoodRecord(name: "Apple", calories: 95.0, protein: 0.5, carbs: 25.0, fat: 0.3)
        let food2 = FoodRecord(name: "Chicken Breast", calories: 165.0, protein: 31.0, carbs: 0.0, fat: 3.6)

        let diary = DailyDiary(foods: [food1, food2])
        XCTAssertEqual(diary.totalCalories, 260.0, accuracy: 0.01)
    }

    func testSwiftDataContainerPersistence() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserProfile.self, DailyDiary.self, FoodRecord.self, configurations: config)
        let context = ModelContext(container)

        let food = FoodRecord(name: "Oatmeal", brand: "Quaker", calories: 150, protein: 5, carbs: 27, fat: 2.5)
        let diary = DailyDiary(foods: [food])
        let user = UserProfile(name: "Alice", weightKg: 65.0, heightCm: 170.0, age: 28, isMale: false)

        context.insert(food)
        context.insert(diary)
        context.insert(user)

        try context.save()

        let profileDescriptor = FetchDescriptor<UserProfile>()
        let profiles = try context.fetch(profileDescriptor)
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.name, "Alice")

        let diaryDescriptor = FetchDescriptor<DailyDiary>()
        let diaries = try context.fetch(diaryDescriptor)
        XCTAssertEqual(diaries.count, 1)
        XCTAssertEqual(diaries.first?.foods.count, 1)
        XCTAssertEqual(diaries.first?.foods.first?.name, "Oatmeal")
    }

    func testFoodRecordWithMealType() {
        let food = FoodRecord(name: "Oatmeal", calories: 150, protein: 5, carbs: 27, fat: 3, mealType: "Breakfast")
        XCTAssertEqual(food.mealType, "Breakfast")
    }

    func testCatalogFoodEntryInitialization() {
        let entry = CatalogFoodEntry(
            id: "12345",
            name: "Greek Yogurt",
            brand: "Chobani",
            calories: 120,
            protein: 15,
            carbs: 6,
            fat: 0,
            servingSize: 170,
            servingUnit: "g",
            barcode: "012345678901"
        )
        XCTAssertEqual(entry.name, "Greek Yogurt")
        XCTAssertEqual(entry.barcode, "012345678901")
    }
}
