import SwiftUI

struct DiaryView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Diary")
                    .foregroundStyle(KalaiTheme.colors.text)
            }
            .navigationTitle("Diary")
        }
        .kalaiBackground()
    }
}
