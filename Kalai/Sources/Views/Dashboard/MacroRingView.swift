import SwiftUI

struct MacroRingView: View {
    let total: Double
    let consumed: Double

    var percentage: Double {
        guard total > 0 else { return 0.0 }
        return min(consumed / total, 1.0)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(KalaiTheme.colors.surface, lineWidth: 20)

            Circle()
                .trim(from: 0, to: percentage)
                .stroke(KalaiTheme.colors.accent, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(KalaiTheme.spring, value: percentage)
        }
        .frame(width: 150, height: 150)
    }
}
