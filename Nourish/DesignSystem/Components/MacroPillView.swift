import SwiftUI

struct MacroPillView: View {
    var title: String
    var amount: String
    var color: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)

            Text(amount)
                .font(.system(.subheadline, design: .rounded).bold())
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(ThemeColors.surfaceBackground)
        .clipShape(Capsule())
    }
}
