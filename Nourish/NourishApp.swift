import SwiftUI
import SwiftData

#if os(iOS)
@main
#endif
struct NourishApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            DailyLog.self,
            FoodItem.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct RootContentView: View {
    @Query private var userProfiles: [UserProfile]
    @State private var onboardingViewModel = OnboardingViewModel()
    @State private var hasCompletedOnboarding: Bool = false

    var body: some View {
        Group {
            if userProfiles.isEmpty && !hasCompletedOnboarding {
                OnboardingFlowView(viewModel: onboardingViewModel) {
                    hasCompletedOnboarding = true
                }
            } else {
                MainTabView()
            }
        }
        .preferredColorScheme(.dark)
    }
}
