import SwiftUI
import SwiftData

struct DiaryView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var selectedDate: Date = Date()

    @State private var selectedFoodItem: FoodItem?
    @State private var mealTypeForManualEntry: MealType?
    @State private var showDatePicker: Bool = false
    @State private var showSearch: Bool = false

    // Reactive query — re-renders automatically whenever the ModelContext changes.
    @Query private var dailyLogs: [DailyLog]

    private var selectedDateString: String {
        DateFormatter.yyyyMMdd.string(from: selectedDate)
    }

    private var currentLog: DailyLog? {
        dailyLogs.first { $0.dateString == selectedDateString }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dateNavigationBar

                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(MealType.allCases) { mealType in
                            mealSection(for: mealType)
                        }
                    }
                    .padding()
                }
            }
            .background(ThemeColors.deepBackground.ignoresSafeArea())
            .navigationTitle("Diary")

            .sheet(item: $selectedFoodItem) { item in
                FoodDetailSheet(foodItem: item) {
                    deleteFoodItem(item)
                }
            }
            .sheet(item: $mealTypeForManualEntry) { mealType in
                ManualFoodEntryView(initialMealType: mealType) { newItem in
                    addFoodItem(newItem)
                }
            }
            .sheet(isPresented: $showSearch) {
                FoodSearchView(initialMealType: .breakfast) { item in
                    addFoodItem(item)
                }
            }
            .sheet(isPresented: $showDatePicker) {
                NavigationStack {
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                        .navigationTitle("Choose Date")

                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showDatePicker = false
                                }
                            }
                        }
                }
                .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Date Navigation Bar

    private var dateNavigationBar: some View {
        HStack {
            Button(action: {
                withAnimation(FluidSprings.standard) {
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(8)
            }

            Spacer()

            Button(action: {
                showDatePicker = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text(formattedDate(selectedDate))
                        .font(.headline)
                }
                .foregroundColor(.primary)
            }

            Spacer()

            Button(action: {
                withAnimation(FluidSprings.standard) {
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(ThemeColors.surfaceBackground)
    }

    private func formattedDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    // MARK: - Meal Sections

    private func mealSection(for mealType: MealType) -> some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: mealType.iconName)
                        .foregroundColor(.accentColor)
                    Text(mealType.displayName)
                        .font(.headline)
                    Spacer()
                    Text("\(Int(totalCalories(for: mealType))) kcal")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                }

                Divider()

                // Food Items
                let items = items(for: mealType)
                if items.isEmpty {
                    Text("No food logged yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(items) { item in
                        foodItemRow(item)
                    }
                }

                // Add Food Button
                Button(action: {
                    mealTypeForManualEntry = mealType
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Food")
                            .font(.subheadline.bold())
                    }
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }
            }
        }
    }

    private func foodItemRow(_ item: FoodItem) -> some View {
        Button(action: {
            selectedFoodItem = item
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        if let brand = item.brand, !brand.isEmpty {
                            Text(brand)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        if let qty = item.servingQuantity, let unit = item.servingUnitName {
                             Text(String(format: "%.1f %@", qty, unit))
                                .font(.caption2.bold())
                                .foregroundColor(ThemeColors.protein)
                        }

                        Text("P: \(Int(item.proteinGrams))g  C: \(Int(item.carbsGrams))g  F: \(Int(item.fatGrams))g")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text("\(Int(item.calories)) kcal")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteFoodItem(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Data Helpers

    private func items(for mealType: MealType) -> [FoodItem] {
        currentLog?.foodItems(for: mealType) ?? []
    }

    private func totalCalories(for mealType: MealType) -> Double {
        items(for: mealType).reduce(0) { $0 + $1.calories }
    }

    private func addFoodItem(_ item: FoodItem) {
        modelContext.insert(item)
        let log: DailyLog
        if let existing = currentLog {
            log = existing
        } else {
            log = DailyLog(dateString: selectedDateString)
            modelContext.insert(log)
        }
        log.foodItems.append(item)
        try? modelContext.save()
    }

    private func deleteFoodItem(_ item: FoodItem) {
        modelContext.delete(item)
        try? modelContext.save()
    }
}