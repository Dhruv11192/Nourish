import SwiftUI

struct OCRLabelScannerOverlay: View {
    @Bindable var viewModel: OCRScannerViewModel
    var captureAction: () -> Void
    var onLogFood: (FoodItem) -> Void

    var body: some View {
        ZStack {
            // Guide
            if case .idle = viewModel.state {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
                    .frame(width: 320, height: 450)

                VStack {
                    Text("Align nutrition facts within box")
                        .font(.subheadline)
                        .padding()
                        .background(.black.opacity(0.6))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .padding(.top, 100)
                    Spacer()
                    Button(action: {
                        HapticFeedback.trigger(.rigid)
                        captureAction()
                    }) {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 4)
                            .frame(width: 72, height: 72)
                            .overlay(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 60, height: 60)
                            )
                    }
                    .padding(.bottom, 40)
                }
            } else if case .scanning = viewModel.state {
                VStack {
                    ProgressView("Analyzing label...")
                        .tint(.white)
                        .foregroundColor(.white)
                        .padding()
                        .background(.black.opacity(0.6))
                        .cornerRadius(12)
                }
            } else if case .recognized(let data) = viewModel.state {
                VStack {
                    Spacer()
                    FrostedCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Nutrition Facts Found")
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(.white)

                            TextField("Enter Food Name", text: $viewModel.nameInput)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(.white)

                            HStack {
                                MacroPillView(title: "Cal", amount: String(format: "%.0f", data.calories ?? 0), color: .gray)
                                MacroPillView(title: "P", amount: String(format: "%.0fg", data.protein ?? 0), color: ThemeColors.protein)
                                MacroPillView(title: "C", amount: String(format: "%.0fg", data.carbs ?? 0), color: ThemeColors.carbs)
                                MacroPillView(title: "F", amount: String(format: "%.0fg", data.fat ?? 0), color: ThemeColors.fat)
                            }

                            Button(action: {
                                if let item = viewModel.createFoodItem() {
                                    HapticFeedback.trigger(.medium)
                                    onLogFood(item)
                                    viewModel.reset()
                                }
                            }) {
                                Text("Log Verified Item")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(ThemeColors.carbs)
                                    .foregroundColor(.black)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(FluidSprings.standard, value: viewModel.state)
                }
            } else if case .failed(let errorMsg) = viewModel.state {
                VStack {
                    Spacer()
                    FrostedCard {
                        VStack(spacing: 12) {
                            Text(errorMsg)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                            Button(action: {
                                viewModel.reset()
                            }) {
                                Text("Try Again")
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
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
    }
}
