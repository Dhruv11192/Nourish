import SwiftUI

struct LiquidProgressRing: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat = 12

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(ThemeColors.surfaceBackground, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(animatedProgress))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .onChange(of: progress) { newValue in
            withAnimation(FluidSprings.standard) {
                animatedProgress = newValue
            }
        }
        .onAppear {
            withAnimation(FluidSprings.standard) {
                animatedProgress = progress
            }
        }
    }
}
