import SwiftUI

struct GoalSelectionStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("What's your goal?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top)

            Text("We'll tailor your nutrition plan to help you get there.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(GoalType.allCases, id: \.self) { goal in
                        Button(action: {
                            withAnimation(FluidSprings.standard) {
                                viewModel.goalType = goal
                            }
                        }) {
                            FrostedCard {
                                HStack(spacing: 16) {
                                    Image(systemName: iconForGoal(goal))
                                        .font(.system(size: 24))
                                        .foregroundColor(ThemeColors.protein)
                                        .frame(width: 40)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(titleForGoal(goal))
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(descriptionForGoal(goal))
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.leading)
                                    }

                                    Spacer()

                                    if viewModel.goalType == goal {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(ThemeColors.protein)
                                    }
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
    }

    private func titleForGoal(_ goal: GoalType) -> String {
        switch goal {
        case .weightLoss: return "Lose Weight"
        case .maintain: return "Maintain Weight"
        case .weightGain: return "Gain Muscle"
        }
    }

    private func descriptionForGoal(_ goal: GoalType) -> String {
        switch goal {
        case .weightLoss: return "Burn fat and lean out with a sustainable calorie deficit."
        case .maintain: return "Maintain your current composition and fuel your lifestyle."
        case .weightGain: return "Build muscle mass with a strategic calorie surplus."
        }
    }

    private func iconForGoal(_ goal: GoalType) -> String {
        switch goal {
        case .weightLoss: return "arrow.down.right.circle.fill"
        case .maintain: return "equal.circle.fill"
        case .weightGain: return "arrow.up.right.circle.fill"
        }
    }
}

struct ActivityLevelSelectionView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Activity Level")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top)

            Text("How active are you on an average day?")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                        Button(action: {
                            withAnimation(FluidSprings.standard) {
                                viewModel.activityLevel = level
                            }
                        }) {
                            FrostedCard {
                                HStack(spacing: 16) {
                                    Image(systemName: iconForActivity(level))
                                        .font(.system(size: 24))
                                        .foregroundColor(ThemeColors.carbs)
                                        .frame(width: 40)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(titleForActivity(level))
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(descriptionForActivity(level))
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.leading)
                                    }

                                    Spacer()

                                    if viewModel.activityLevel == level {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(ThemeColors.carbs)
                                    }
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
    }

    private func titleForActivity(_ level: ActivityLevel) -> String {
        switch level {
        case .sedentary: return "Sedentary"
        case .lightlyActive: return "Lightly Active"
        case .moderatelyActive: return "Moderately Active"
        case .veryActive: return "Very Active"
        case .extremelyActive: return "Extremely Active"
        }
    }

    private func descriptionForActivity(_ level: ActivityLevel) -> String {
        switch level {
        case .sedentary: return "Desk job, little to no exercise."
        case .lightlyActive: return "Light exercise 1-3 days a week."
        case .moderatelyActive: return "Moderate exercise 3-5 days a week."
        case .veryActive: return "Heavy exercise 6-7 days a week."
        case .extremelyActive: return "Very heavy exercise, physical job, training 2x a day."
        }
    }

    private func iconForActivity(_ level: ActivityLevel) -> String {
        switch level {
        case .sedentary: return "desktopcomputer"
        case .lightlyActive: return "figure.walk"
        case .moderatelyActive: return "figure.run"
        case .veryActive: return "figure.highintensity.intervaltraining"
        case .extremelyActive: return "flame.fill"
        }
    }
}
