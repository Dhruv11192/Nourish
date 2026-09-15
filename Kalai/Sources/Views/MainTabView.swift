import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DiaryView()
                .tabItem {
                    Label("Diary", systemImage: "book")
                }

            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie")
                }
        }
        .tint(KalaiTheme.colors.accent)
        .kalaiBackground()
    }
}
