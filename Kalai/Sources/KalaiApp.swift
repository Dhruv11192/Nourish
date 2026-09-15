import SwiftUI
import SwiftData

@main
struct KalaiApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [UserProfile.self, DailyDiary.self, FoodRecord.self])
    }
}
