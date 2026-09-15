import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Dashboard")
                    .foregroundStyle(KalaiTheme.colors.text)
            }
            .navigationTitle("Dashboard")
        }
        .kalaiBackground()
    }
}
