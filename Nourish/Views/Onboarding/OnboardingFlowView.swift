import SwiftUI
import SwiftData

struct OnboardingFlowView: View {
    @Bindable var viewModel: OnboardingViewModel
    var onComplete: () -> Void

    @State private var stepDirection: Int = 1 // 1 forward, -1 back

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            // Progress Header
            VStack(spacing: 8) {
                HStack {
                    ForEach(OnboardingViewModel.OnboardingStep.allCases) { step in
                        stepIndicator(isActive: step.rawValue <= viewModel.currentStep.rawValue)
                    }
                }
                .padding(.horizontal)

                Text("\(viewModel.currentStep.rawValue + 1) of \(OnboardingViewModel.OnboardingStep.allCases.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.gray)
            }
            .padding(.top)
            .padding(.bottom, 8)

            // Step Content with slide + fade transitions
            ZStack {
                switch viewModel.currentStep {
                case .welcome:
                    WelcomeStepView(viewModel: viewModel)
                case .biometrics:
                    MetricInputStepView(viewModel: viewModel)
                case .activity:
                    ActivityLevelSelectionView(viewModel: viewModel)
                case .goal:
                    GoalSelectionStepView(viewModel: viewModel)
                case .pace:
                    PaceSelectionStepView(viewModel: viewModel)
                case .macroSplit:
                    MacroSplitStepView(viewModel: viewModel)
                case .summary:
                    PlanSummaryStepView(viewModel: viewModel, onComplete: onComplete)
                }
            }
            .id(viewModel.currentStep)
            .transition(.asymmetric(
                insertion: .move(edge: stepDirection > 0 ? .trailing : .leading).combined(with: .opacity),
                removal: .move(edge: stepDirection > 0 ? .leading : .trailing).combined(with: .opacity)
            ))
            .frame(maxHeight: .infinity)

            // Bottom Navigation
            bottomNavigation
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .background(ThemeColors.deepBackground)
        .animation(FluidSprings.standard, value: viewModel.currentStep)
    }

    private func stepIndicator(isActive: Bool) -> some View {
        Capsule()
            .fill(isActive ? ThemeColors.protein : ThemeColors.surfaceBackground)
            .frame(height: 4)
            .frame(maxWidth: .infinity)
    }

    private var bottomNavigation: some View {
        HStack(spacing: 16) {
            if viewModel.currentStep != .welcome {
                Button(action: {
                    stepDirection = -1
                    withAnimation(FluidSprings.standard) {
                        viewModel.previousStep()
                    }
                }) {
                    Label("Back", systemImage: "chevron.left")
                        .font(.headline)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(ThemeColors.surfaceBackground)
                        .clipShape(Capsule())
                }
                .foregroundColor(.white)
            } else {
                // Spacer to keep Next aligned
                Spacer().frame(maxWidth: .infinity)
            }

            Spacer()

            NavigationButton(title: viewModel.currentStep == .summary ? "Done" : "Next",
                             color: ThemeColors.protein,
                             systemImage: viewModel.currentStep == .summary ? "checkmark" : "arrow.right") {
                stepDirection = 1
                withAnimation(FluidSprings.standard) {
                    if viewModel.currentStep == .summary {
                        viewModel.saveToSwiftData(context: modelContext)
                        onComplete()
                    } else {
                        viewModel.nextStep()
                    }
                }
            }
            .opacity(viewModel.canProceed ? 1 : 0.5)
            .disabled(!viewModel.canProceed)
        }
    }
}

// MARK: - Shared Button

private struct NavigationButton: View {
    var title: String
    var color: Color
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundColor(ThemeColors.deepBackground)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(color)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Welcome Step

struct WelcomeStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 72))
                .foregroundColor(ThemeColors.protein)
                .padding(.top, 60)

            Text("Welcome to Nourish")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("Mindful nutrition, tailored to your body. Let's build a plan together — it only takes a minute.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            FrostedCard {
                HStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(ThemeColors.carbs)
                    Text("Sustainable habits, not crash diets")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Pace Step

struct PaceSelectionStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    private var paces: [Double] {
        switch viewModel.goalType {
        case .weightLoss: return [-1.0, -0.75, -0.5, -0.25]
        case .weightGain: return [0.25, 0.5, 0.75, 1.0]
        case .maintain: return [0.0]
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Pace Your Progress")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top)

            Text(viewModel.goalType == .maintain
                 ? "You're maintaining — no calorie adjustment needed."
                 : "How quickly would you like to change weight per week?")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            if viewModel.goalType != .maintain {
                VStack(spacing: 16) {
                    ForEach(paces, id: \.self) { pace in
                        Button(action: {
                            withAnimation(FluidSprings.standard) {
                                viewModel.weeklyWeightChangeKg = pace
                            }
                        }) {
                            FrostedCard {
                                HStack {
                                    Text(paceLabel(for: pace))
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    Spacer()

                                    if abs(viewModel.weeklyWeightChangeKg - pace) < 0.001 {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(ThemeColors.protein)
                                    }
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 32)
            } else {
                FrostedCard {
                    Text("Maintaining weight at your current calorie baseline.")
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func paceLabel(for pace: Double) -> String {
        if pace < 0 {
            let formatted = formattedPace(abs(pace))
            return "Lose \(formatted) kg/week"
        } else if pace > 0 {
            return "Gain \(formattedPace(pace)) kg/week"
        } else {
            return "Maintain Current Weight"
        }
    }

    private func formattedPace(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
}

// MARK: - Macro Split Step

struct MacroSplitStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Macro Balance")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top)

            Text("Balance protein, carbs and fat to match your goals.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Presets
            HStack(spacing: 8) {
                presetButton("Balanced", p: 30, c: 40, f: 30)
                presetButton("High Protein", p: 40, c: 35, f: 25)
                presetButton("Low Carb", p: 35, c: 15, f: 45)
            }
            .padding(.horizontal)

            ScrollView {
                VStack(spacing: 24) {
                    macroSlider(title: "Protein", value: $viewModel.proteinPercentage, tint: ThemeColors.protein)
                    macroSlider(title: "Carbs", value: $viewModel.carbsPercentage, tint: ThemeColors.carbs)
                    macroSlider(title: "Fat", value: $viewModel.fatPercentage, tint: ThemeColors.fat)
                }
                .padding()
            }
        }
    }

    private func presetButton(_ name: String, p: Double, c: Double, f: Double) -> some View {
        let isSelected = abs(viewModel.proteinPercentage - p) < 0.5
            && abs(viewModel.carbsPercentage - c) < 0.5
            && abs(viewModel.fatPercentage - f) < 0.5

        return Button(action: {
            withAnimation(FluidSprings.standard) {
                viewModel.proteinPercentage = p
                viewModel.carbsPercentage = c
                viewModel.fatPercentage = f
            }
        }) {
            Text(name)
                .font(.subheadline.bold())
                .foregroundColor(isSelected ? ThemeColors.deepBackground : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(isSelected ? ThemeColors.protein : ThemeColors.surfaceBackground)
                .clipShape(Capsule())
        }
    }

    private func macroSlider(title: String, value: Binding<Double>, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(value.wrappedValue))%")
                    .font(.headline.monospacedDigit())
                    .foregroundColor(tint)
            }
            Slider(value: value, in: 5...70, step: 5)
                .tint(tint)
        }
        .padding()
        .background(ThemeColors.surfaceBackground)
        .cornerRadius(16)
    }
}