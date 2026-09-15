import SwiftUI
import SwiftData

@main
struct KalaiApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: UserProfile.self, DailyDiary.self, FoodRecord.self, CatalogFoodEntry.self)
            seedDefaultCatalogIfNeeded()
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }

    private func seedDefaultCatalogIfNeeded() {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<CatalogFoodEntry>()
        descriptor.fetchLimit = 1
        if let count = try? context.fetchCount(descriptor), count == 0 {
            if let url = Bundle.main.url(forResource: "foods", withExtension: "json"),
               let data = try? Data(contentsOf: url) {
                DataSeeder.seedInitialFoods(into: context, foodsData: data)
            }
        }
    }
}
