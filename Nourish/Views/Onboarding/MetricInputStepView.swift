import SwiftUI

struct MetricInputStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var isMetric: Bool = true

    var body: some View {
        VStack(spacing: 24) {
            Text("About You")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top)

            Picker("System", selection: $isMetric) {
                Text("Metric").tag(true)
                Text("Imperial").tag(false)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            ScrollView {
                VStack(spacing: 32) {

                    // Sex
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Biological Sex")
                            .font(.headline)
                            .foregroundColor(.gray)

                        Picker("Sex", selection: $viewModel.biologicalSex) {
                            Text("Male").tag(BiologicalSex.male)
                            Text("Female").tag(BiologicalSex.female)
                        }
                        .pickerStyle(.segmented)
                    }

                    // Age
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Age")
                            .font(.headline)
                            .foregroundColor(.gray)

                        HStack {
                            Slider(value: Binding(
                                get: { Double(viewModel.age) },
                                set: { viewModel.age = Int($0) }
                            ), in: 13...100, step: 1)
                            .tint(ThemeColors.protein)

                            Text("\(viewModel.age) yrs")
                                .font(.headline.monospacedDigit())
                                .foregroundColor(.white)
                                .frame(width: 70, alignment: .trailing)
                        }
                    }

                    // Height
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Height")
                            .font(.headline)
                            .foregroundColor(.gray)

                        if isMetric {
                            HStack {
                                Slider(value: $viewModel.heightCm, in: 120...220, step: 1)
                                    .tint(ThemeColors.protein)

                                Text("\(Int(viewModel.heightCm)) cm")
                                    .font(.headline.monospacedDigit())
                                    .foregroundColor(.white)
                                    .frame(width: 70, alignment: .trailing)
                            }
                        } else {
                            // Imperial Height
                            let totalInches = viewModel.heightCm / 2.54
                            HStack {
                                Slider(value: Binding(
                                    get: { totalInches },
                                    set: { viewModel.heightCm = $0 * 2.54 }
                                ), in: 47...86, step: 1)
                                .tint(ThemeColors.protein)

                                let ft = Int(totalInches) / 12
                                let inch = Int(totalInches) % 12
                                Text("\(ft)'\(inch)\"")
                                    .font(.headline.monospacedDigit())
                                    .foregroundColor(.white)
                                    .frame(width: 70, alignment: .trailing)
                            }
                        }
                    }

                    // Weight
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weight")
                            .font(.headline)
                            .foregroundColor(.gray)

                        if isMetric {
                            HStack {
                                Slider(value: $viewModel.weightKg, in: 40...200, step: 0.5)
                                    .tint(ThemeColors.protein)

                                Text(String(format: "%.1f kg", viewModel.weightKg))
                                    .font(.headline.monospacedDigit())
                                    .foregroundColor(.white)
                                    .frame(width: 70, alignment: .trailing)
                            }
                        } else {
                            let lbs = viewModel.weightKg * 2.20462
                            HStack {
                                Slider(value: Binding(
                                    get: { lbs },
                                    set: { viewModel.weightKg = $0 / 2.20462 }
                                ), in: 88...440, step: 1)
                                .tint(ThemeColors.protein)

                                Text("\(Int(lbs)) lbs")
                                    .font(.headline.monospacedDigit())
                                    .foregroundColor(.white)
                                    .frame(width: 70, alignment: .trailing)
                            }
                        }
                    }
                }
                .padding(24)
                .background(FrostedCard { Color.clear }) // Using FrostedCard styling concept intuitively or actual FrostedCard.
                .padding(.horizontal)
            }
        }
    }
}
