import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DashboardViewModel()

    @State private var showScanner: Bool = false
    @State private var mealTypeForManualEntry: MealType?
    @State private var selectedScannerMealType: MealType = .snack

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 20) {
                        calorieProgressCard
                        macroTargetsCard
                        activityCard
                        waterCard
                        quickLogMealSection
                    }
                    .padding()
                    .padding(.bottom, 60) // Extra padding for FAB
                }

                // Floating Action Button for Scanner
                Button(action: {
                    showScanner = true
                }) {
                    Image(systemName: "camera.viewfinder")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(ThemeColors.protein)
                        .clipShape(Circle())
                        .shadow(color: ThemeColors.protein.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .background(ThemeColors.deepBackground.ignoresSafeArea())
            .navigationTitle("Dashboard")
            .onAppear {
                viewModel.loadData(context: modelContext)
            }
            .sheet(isPresented: $showScanner) {
                UnifiedScannerView(
                    onLogFood: { item in
                        item.mealType = selectedScannerMealType
                        logFoodItem(item)
                    },
                    onLogFoods: { items in
                        for item in items {
                            item.mealType = selectedScannerMealType
                            logFoodItem(item)
                        }
                    }
                )
            }
            .sheet(item: $mealTypeForManualEntry) { mealType in
                ManualFoodEntryView(initialMealType: mealType) { newItem in
                    logFoodItem(newItem)
                }
            }
        }
    }

    private func logFoodItem(_ item: FoodItem) {
        let todayString = DateFormatter.yyyyMMdd.string(from: Date())
        let descriptor = FetchDescriptor<DailyLog>(predicate: #Predicate<DailyLog> { log in
            log.dateString == todayString
        })

        if let todayLog = try? modelContext.fetch(descriptor).first {
            todayLog.foodItems.append(item)
        } else {
            let newLog = DailyLog(dateString: todayString, foodItems: [item])
            modelContext.insert(newLog)
        }
        try? modelContext.save()

        // Reload data so the view updates
        viewModel.loadData(context: modelContext)
    }

    // MARK: - Calorie Card

    private var calorieProgressCard: some View {
        FrostedCard {
            VStack(spacing: 16) {
                Text("Calories Remaining")
                    .font(.headline)
                    .foregroundColor(.secondary)

                ZStack {
                    LiquidProgressRing(
                        progress: viewModel.calorieGoal > 0 ? (viewModel.consumedCalories / viewModel.calorieGoal) : 0,
                        color: ThemeColors.protein,
                        lineWidth: 16
                    )
                    .frame(width: 180, height: 180)

                    VStack(spacing: 4) {
                        Text("\(Int(viewModel.caloriesRemaining))")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                        Text("kcal left")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)

                HStack(spacing: 20) {
                    VStack {
                        Text("Base Goal")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(Int(viewModel.calorieGoal))")
                            .font(.subheadline.bold())
                    }

                    Divider()
                        .frame(height: 24)

                    VStack {
                        Text("Food")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(Int(viewModel.consumedCalories))")
                            .font(.subheadline.bold())
                    }

                    Divider()
                        .frame(height: 24)

                    VStack {
                        Text("Burned")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(Int(viewModel.burnedCalories))")
                            .font(.subheadline.bold())
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Macros Card

    private var macroTargetsCard: some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Macronutrients")
                    .font(.headline)

                VStack(spacing: 12) {
                    macroBar(
                        title: "Protein",
                        current: viewModel.todayLog?.totalProtein ?? 0,
                        target: viewModel.userProfile?.targetProteinGrams ?? 150,
                        progress: viewModel.proteinProgress,
                        color: ThemeColors.protein
                    )

                    macroBar(
                        title: "Carbs",
                        current: viewModel.todayLog?.totalCarbs ?? 0,
                        target: viewModel.userProfile?.targetCarbsGrams ?? 200,
                        progress: viewModel.carbsProgress,
                        color: ThemeColors.carbs
                    )

                    macroBar(
                        title: "Fat",
                        current: viewModel.todayLog?.totalFat ?? 0,
                        target: viewModel.userProfile?.targetFatGrams ?? 65,
                        progress: viewModel.fatProgress,
                        color: ThemeColors.fat
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func macroBar(title: String, current: Double, target: Double, progress: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.bold())
                Spacer()
                Text("\(Int(current)) / \(Int(target))g")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(ThemeColors.surfaceBackground)
                        .frame(height: 10)

                    Capsule()
                        .fill(color)
                        .frame(width: max(0, min(geo.size.width * CGFloat(progress), geo.size.width)), height: 10)
                }
            }
            .frame(height: 10)
        }
    }

    // MARK: - Activity Card

    private var activityCard: some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.green)
                    Text("Activity & Health")
                        .font(.headline)
                }

                HStack(spacing: 20) {
                    HStack(spacing: 12) {
                        Image(systemName: "flame.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Int(viewModel.burnedCalories)) kcal")
                                .font(.headline)
                            Text("Active Energy")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()
                        .frame(height: 40)

                    HStack(spacing: 12) {
                        Image(systemName: "shoeprints.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(viewModel.steps)")
                                .font(.headline)
                            Text("Steps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Water Card

    private var waterCard: some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(ThemeColors.water)
                    Text("Water Intake")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(viewModel.todayLog?.waterIntakeMl ?? 0)) / \(Int(viewModel.userProfile?.targetWaterIntakeMl ?? 2500)) ml")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Water progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(ThemeColors.surfaceBackground)
                            .frame(height: 12)

                        Capsule()
                            .fill(ThemeColors.water)
                            .frame(width: max(0, min(geo.size.width * CGFloat(viewModel.waterProgress), geo.size.width)), height: 12)
                    }
                }
                .frame(height: 12)

                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.addWater(amountMl: 250, context: modelContext)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("250 ml")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(ThemeColors.water)
                        .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Quick Log Meals

    private var quickLogMealSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Log")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(MealType.allCases) { mealType in
                    Button(action: {
                        selectedScannerMealType = mealType
                        mealTypeForManualEntry = mealType
                    }) {
                        FrostedCard {
                            HStack {
                                Image(systemName: mealType.iconName)
                                    .font(.title3)
                                    .foregroundColor(.accentColor)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mealType.displayName)
                                        .font(.subheadline.bold())
                                        .foregroundColor(.primary)
                                    Text("Log Food")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
