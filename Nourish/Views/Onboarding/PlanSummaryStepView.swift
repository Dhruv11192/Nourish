import SwiftUI

struct PlanSummaryStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Your Personalized Plan")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top)

            ScrollView {
                VStack(spacing: 32) {
                    // Calories Ring
                    ZStack {
                        LiquidProgressRing(progress: 1.0, color: ThemeColors.protein, lineWidth: 16)
                            .frame(width: 200, height: 200)

                        VStack(spacing: 4) {
                            Text("\(Int(viewModel.calculatedDailyCalories))")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("kcal / day")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 16)

                    // Macro Cards
                    HStack(spacing: 16) {
                        macroCard(
                            title: "Protein",
                            amount: "\(Int(viewModel.calculatedMacroTargets.protein))g",
                            color: ThemeColors.protein
                        )
                        macroCard(
                            title: "Carbs",
                            amount: "\(Int(viewModel.calculatedMacroTargets.carbs))g",
                            color: ThemeColors.carbs
                        )
                        macroCard(
                            title: "Fat",
                            amount: "\(Int(viewModel.calculatedMacroTargets.fat))g",
                            color: ThemeColors.fat
                        )
                    }
                    .padding(.horizontal)

                    // Water Intake
                    FrostedCard {
                        HStack {
                            Image(systemName: "drop.fill")
                                .font(.title)
                                .foregroundColor(ThemeColors.water)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Daily Water Goal")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Stay hydrated for optimal metabolism.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Text(String(format: "%.1f L", viewModel.waterIntakeLiters))
                                .font(.title3.bold())
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)

                    // Additional Info (TDEE, BMR)
                    VStack(spacing: 8) {
                        Text("Metabolic Profile")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("BMR")
                                    .foregroundColor(.gray)
                                Text("\(Int(viewModel.calculatedBMR)) kcal")
                                    .foregroundColor(.white)
                                    .bold()
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("TDEE")
                                    .foregroundColor(.gray)
                                Text("\(Int(viewModel.calculatedTDEE)) kcal")
                                    .foregroundColor(.white)
                                    .bold()
                            }
                        }
                        .padding()
                        .background(ThemeColors.surfaceBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 32)
            }

            Button(action: {
                onComplete()
            }) {
                Text("Begin Journey")
                    .font(.headline)
                    .foregroundColor(ThemeColors.deepBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(ThemeColors.protein)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private func macroCard(title: String, amount: String, color: Color) -> some View {
        FrostedCard {
            VStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(amount)
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
