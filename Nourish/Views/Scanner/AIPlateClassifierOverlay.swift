import SwiftUI

struct AIPlateClassifierOverlay: View {
    @Bindable var viewModel: AIPlateScannerViewModel
    var captureAction: () -> Void
    var onLogFoods: ([FoodItem]) -> Void

    private let portionOptions: [Double] = [0.5, 1.0, 1.5, 2.0]

    private var selectedCandidateList: [EstimatedFoodCandidate] {
        guard case .results(let candidates) = viewModel.state else { return [] }
        return candidates.filter { viewModel.selectedCandidates.contains($0.id) }
    }

    private var aggregateCalories: Double {
        selectedCandidateList.reduce(0) { $0 + ($1.calories * viewModel.portionMultiplier) }
    }

    private var aggregateProtein: Double {
        selectedCandidateList.reduce(0) { $0 + ($1.proteinGrams * viewModel.portionMultiplier) }
    }

    private var aggregateCarbs: Double {
        selectedCandidateList.reduce(0) { $0 + ($1.carbsGrams * viewModel.portionMultiplier) }
    }

    private var aggregateFat: Double {
        selectedCandidateList.reduce(0) { $0 + ($1.fatGrams * viewModel.portionMultiplier) }
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .idle:
                idleCaptureView
            case .capturing, .analyzing:
                analyzingView
            case .results(let candidates):
                resultsView(candidates: candidates)
            case .empty:
                emptyView
            case .failed(let message):
                failedView(message: message)
            }
        }
    }

    // MARK: - Subviews

    private var idleCaptureView: some View {
        VStack {
            Text("Point camera at your meal plate")
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.black.opacity(0.6))
                .foregroundColor(.white)
                .clipShape(Capsule())
                .padding(.top, 100)

            Spacer()

            // Large circular camera shutter
            Button(action: {
                HapticFeedback.trigger(.medium)
                captureAction()
            }) {
                Circle()
                    .strokeBorder(Color.white, lineWidth: 4)
                    .frame(width: 76, height: 76)
                    .overlay(
                        Circle()
                            .fill(ThemeColors.protein)
                            .frame(width: 62, height: 62)
                    )
            }
            .padding(.bottom, 40)
        }
    }

    private var analyzingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)

            Text("Analyzing Meal with AI...")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(24)
        .background(.black.opacity(0.7))
        .cornerRadius(16)
    }

    private func resultsView(candidates: [EstimatedFoodCandidate]) -> some View {
        VStack {
            Spacer()

            FrostedCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Detected Foods")
                            .font(.system(.headline, design: .rounded).bold())
                            .foregroundColor(.white)

                        Spacer()

                        // Portion multiplier picker
                        HStack(spacing: 6) {
                            ForEach(portionOptions, id: \.self) { multiplier in
                                Button(action: {
                                    withAnimation(FluidSprings.standard) {
                                        viewModel.portionMultiplier = multiplier
                                    }
                                }) {
                                    Text(String(format: "%.1fx", multiplier))
                                        .font(.system(.caption2, design: .rounded).bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            viewModel.portionMultiplier == multiplier
                                                ? ThemeColors.protein
                                                : Color.white.opacity(0.15)
                                        )
                                        .foregroundColor(
                                            viewModel.portionMultiplier == multiplier
                                                ? .black
                                                : .white
                                        )
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Candidate list
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(candidates) { candidate in
                                candidateRow(candidate: candidate)
                            }
                        }
                    }
                    .frame(maxHeight: 180)

                    Divider()
                        .background(Color.white.opacity(0.2))

                    // Aggregated summary pill row
                    HStack(spacing: 8) {
                        MacroPillView(
                            title: "Cal",
                            amount: "\(Int(aggregateCalories))",
                            color: .gray
                        )
                        MacroPillView(
                            title: "P",
                            amount: "\(Int(aggregateProtein))g",
                            color: ThemeColors.protein
                        )
                        MacroPillView(
                            title: "C",
                            amount: "\(Int(aggregateCarbs))g",
                            color: ThemeColors.carbs
                        )
                        MacroPillView(
                            title: "F",
                            amount: "\(Int(aggregateFat))g",
                            color: ThemeColors.fat
                        )
                    }

                    // Log button
                    Button(action: {
                        HapticFeedback.trigger(.rigid)

                        let items = viewModel.generateFoodItemsToLog()
                        onLogFoods(items)
                        viewModel.reset()
                    }) {
                        Text("Log Selected Items (\(selectedCandidateList.count))")
                            .font(.system(.headline, design: .rounded).bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                selectedCandidateList.isEmpty
                                    ? Color.gray.opacity(0.5)
                                    : ThemeColors.protein
                            )
                            .foregroundColor(selectedCandidateList.isEmpty ? .white.opacity(0.5) : .black)
                            .cornerRadius(12)
                    }
                    .disabled(selectedCandidateList.isEmpty)
                }
            }
            .padding()
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func candidateRow(candidate: EstimatedFoodCandidate) -> some View {
        let isSelected = viewModel.selectedCandidates.contains(candidate.id)
        let scaled = candidate.scaled(by: viewModel.portionMultiplier)

        return HStack {
            Button(action: {
                withAnimation(FluidSprings.standard) {
                    viewModel.toggleSelection(for: candidate.id)
                }
            }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? ThemeColors.protein : .gray)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(candidate.name)
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundColor(.white)

                Text("\(Int(scaled.calories)) kcal • \(Int(scaled.servingGrams))g")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Confidence indicator
            Text("\(Int(candidate.confidence * 100))%")
                .font(.system(.caption2, design: .rounded))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.1))
                .foregroundColor(.white.opacity(0.8))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    private var emptyView: some View {
        VStack {
            Spacer()
            FrostedCard {
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 36))
                        .foregroundColor(.gray)

                    Text("No Food Detected")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Make sure the plate is well lit and clearly centered in frame.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    Button(action: {
                        viewModel.reset()
                    }) {
                        Text("Try Again")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 4)
                }
                .padding()
            }
            .padding()
        }
    }

    private func failedView(message: String) -> some View {
        VStack {
            Spacer()
            FrostedCard {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 36))
                        .foregroundColor(ThemeColors.protein)

                    Text("Analysis Error")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    Button(action: {
                        viewModel.reset()
                    }) {
                        Text("Try Again")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                }
                .padding()
            }
            .padding()
        }
    }
}
