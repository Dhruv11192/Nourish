import SwiftUI
import SwiftData

enum TabItem: Int, CaseIterable {
    case dashboard = 0
    case diary = 1
    case analytics = 2
    case profile = 3

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .diary: return "Diary"
        case .analytics: return "Analytics"
        case .profile: return "Profile"
        }
    }

    var iconName: String {
        switch self {
        case .dashboard: return "house.fill"
        case .diary: return "book.closed.fill"
        case .analytics: return "chart.bar.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: TabItem = .dashboard
    @State private var showScanner: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                case .diary:
                    DiaryView()
                case .analytics:
                    AnalyticsPlaceholderView()
                case .profile:
                    ProfilePlaceholderView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            customTabBar
        }
        .sheet(isPresented: $showScanner) {
            UnifiedScannerView(
                onLogFood: { item in
                    logFoodItem(item)
                },
                onLogFoods: { items in
                    for item in items {
                        logFoodItem(item)
                    }
                }
            )
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(for: .dashboard)
            tabButton(for: .diary)

            // Center Scan Action
            centerScanButton

            tabButton(for: .analytics)
            tabButton(for: .profile)
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 24)
        .background(
            ThemeColors.surfaceBackground
                .shadow(color: Color.black.opacity(0.3), radius: 10, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(for tab: TabItem) -> some View {
        Button(action: {
            HapticFeedback.trigger(.light)
            selectedTab = tab
        }) {
            VStack(spacing: 4) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 20))
                Text(tab.title)
                    .font(.caption2)
            }
            .foregroundColor(selectedTab == tab ? ThemeColors.protein : .secondary)
            .frame(maxWidth: .infinity)
        }
    }

    private var centerScanButton: some View {
        Button(action: {
            HapticFeedback.trigger(.medium)
            showScanner = true
        }) {
            ZStack {
                Circle()
                    .fill(ThemeColors.protein.opacity(0.3))
                    .frame(width: 58, height: 58)
                    .blur(radius: 4)

                Circle()
                    .fill(ThemeColors.protein)
                    .frame(width: 50, height: 50)
                    .shadow(color: ThemeColors.protein.opacity(0.5), radius: 6, x: 0, y: 3)

                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            .offset(y: -14)
            .frame(maxWidth: .infinity)
        }
    }

    private func logFoodItem(_ item: FoodItem) {
        let todayString = DateFormatter.yyyyMMdd.string(from: Date())
        let descriptor = FetchDescriptor<DailyLog>(predicate: #Predicate<DailyLog> { log in
            log.dateString == todayString
        })

        if let todayLog = try? modelContext.fetch(descriptor).first {
            todayLog.foodItems.append(item)
        } else {
            let newLog = DailyLog(dateString: todayString, foodItems: [item])
            modelContext.insert(newLog)
        }
        try? modelContext.save()
    }
}

// MARK: - Placeholders

struct AnalyticsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 64))
                    .foregroundColor(ThemeColors.carbs)
                Text("Analytics & Progress")
                    .font(.title2.bold())
                Text("Macro trends, calorie history, and weight projections will appear here.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ThemeColors.deepBackground.ignoresSafeArea())
            .navigationTitle("Analytics")
        }
    }
}

struct ProfilePlaceholderView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let profile = userProfiles.first {
                    FrostedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Metabolic Profile")
                                .font(.headline)
                            Divider()
                            HStack {
                                Text("Daily Target")
                                Spacer()
                                Text("\(Int(profile.targetDailyCalories)) kcal").bold()
                            }
                            HStack {
                                Text("Protein Goal")
                                Spacer()
                                Text("\(Int(profile.targetProteinGrams))g").bold()
                            }
                            HStack {
                                Text("Carbs Goal")
                                Spacer()
                                Text("\(Int(profile.targetCarbsGrams))g").bold()
                            }
                            HStack {
                                Text("Fat Goal")
                                Spacer()
                                Text("\(Int(profile.targetFatGrams))g").bold()
                            }
                        }
                    }
                    .padding()
                } else {
                    Text("No Profile Found")
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ThemeColors.deepBackground.ignoresSafeArea())
            .navigationTitle("Profile")
        }
    }
}
