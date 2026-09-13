import SwiftUI

struct BarcodeScannerOverlay: View {
    @Bindable var viewModel: BarcodeScannerViewModel
    var onLogFood: (FoodItem) -> Void

    @State private var laserOffset: CGFloat = -60

    var body: some View {
        ZStack {
            // Targeting reticle
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.8), lineWidth: 2)
                .frame(width: 300, height: 180)
                .overlay {
                    // Pulsing laser line
                    Rectangle()
                        .fill(ThemeColors.protein)
                        .frame(height: 2)
                        .offset(y: laserOffset)
                        .onAppear {
                            withAnimation(
                                .easeInOut(duration: 1.5).repeatForever(autoreverses: true)
                            ) {
                                laserOffset = 60
                            }
                        }
                }

            // Results Sheet
            if case .success(let foodItem) = viewModel.state {
                VStack {
                    Spacer()
                    FrostedCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(foodItem.name)
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(.white)

                            HStack {
                                MacroPillView(title: "Cal", amount: "\(Int(foodItem.calories))", color: .gray)
                                MacroPillView(title: "P", amount: "\(Int(foodItem.proteinGrams))g", color: ThemeColors.protein)
                                MacroPillView(title: "C", amount: "\(Int(foodItem.carbsGrams))g", color: ThemeColors.carbs)
                                MacroPillView(title: "F", amount: "\(Int(foodItem.fatGrams))g", color: ThemeColors.fat)
                            }

                            Button(action: {
                                // Haptic feedback
                                HapticFeedback.trigger(.medium)

                                onLogFood(foodItem)
                                viewModel.reset()
                            }) {
                                Text("Log Meal")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(ThemeColors.protein)
                                    .foregroundColor(.black)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(FluidSprings.standard, value: viewModel.state)
                }
            } else if viewModel.isLoading {
                VStack {
                    Spacer()
                    FrostedCard {
                        ProgressView("Fetching product...")
                            .tint(.white)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .padding()
                }
            } else if case .error(let msg) = viewModel.state {
                VStack {
                    Spacer()
                    FrostedCard {
                        Text(msg)
                            .foregroundColor(.red)
                            .font(.headline)
                            .padding()
                    }
                    .padding()
                }
            }
        }
    }
}
