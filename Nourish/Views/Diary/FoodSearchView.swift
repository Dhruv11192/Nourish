import SwiftUI

struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    var initialMealType: MealType = .lunch
    var onSelectFood: ((FoodItem) -> Void)?

    @State private var searchText: String = ""
    @State private var selectedMealType: MealType = .lunch
    @State private var portionConfirmation: PendingFoodPortion?
    @State private var showManualCustomEntry: Bool = false

    init(
        initialMealType: MealType = .lunch,
        onSelectFood: ((FoodItem) -> Void)? = nil
    ) {
        self.initialMealType = initialMealType
        self._selectedMealType = State(initialValue: initialMealType)
        self.onSelectFood = onSelectFood
    }

    private var searchResults: [LocalFoodItem] {
        LocalFoodDatabase.search(query: searchText)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search & Filter Header
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search food, brand, or Indian dish...", text: $searchText)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(ThemeColors.surfaceBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    // Meal Type Selector
                    Picker("Meal", selection: $selectedMealType) {
                        ForEach(MealType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(ThemeColors.deepBackground)

                // Results or Popular Foods List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if searchText.isEmpty {
                            HStack {
                                Text("Popular & Indian Foods")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }

                        ForEach(searchResults) { item in
                            foodRow(item)
                        }

                        // Custom Food Entry Action
                        Button(action: {
                            showManualCustomEntry = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Can't find it? Add Custom Food")
                                    .font(.subheadline.bold())
                            }
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ThemeColors.surfaceBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 24)
                }
            }
            .background(ThemeColors.deepBackground.ignoresSafeArea())
            .navigationTitle("Search Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $portionConfirmation) { pending in
                ManualFoodEntryView(prefilledItem: pending.item, initialMealType: selectedMealType) { confirmedItem in
                    portionConfirmation = nil
                    onSelectFood?(confirmedItem)
                    dismiss()
                }
            }
            .sheet(isPresented: $showManualCustomEntry) {
                ManualFoodEntryView(initialMealType: selectedMealType) { customItem in
                    showManualCustomEntry = false
                    onSelectFood?(customItem)
                    dismiss()
                }
            }
        }
    }

    private func foodRow(_ item: LocalFoodItem) -> some View {
        Button(action: {
            let foodItem = createFoodItem(from: item)
            portionConfirmation = PendingFoodPortion(item: foodItem)
        }) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.body.bold())
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        if let desc = item.servingDescription {
                            Text(desc)
                                .font(.caption.bold())
                                .foregroundColor(ThemeColors.protein)
                        }

                        Text("P: \(Int(item.proteinGrams))g  C: \(Int(item.carbsGrams))g  F: \(Int(item.fatGrams))g")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(item.calories))")
                        .font(.headline.bold())
                        .foregroundColor(.primary)
                    Text("kcal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(ThemeColors.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }

    private func createFoodItem(from item: LocalFoodItem) -> FoodItem {
        var unitName = "Serving"
        let desc = item.servingDescription ?? ""

        for unit in ManualFoodEntryView.ServingUnit.allCases {
            if desc.localizedCaseInsensitiveContains(unit.displayName) {
                unitName = unit.displayName
                break
            }
        }

        return FoodItem(
            name: item.name,
            brand: "Nourish Database",
            calories: item.calories,
            proteinGrams: item.proteinGrams,
            carbsGrams: item.carbsGrams,
            fatGrams: item.fatGrams,
            mealType: selectedMealType,
            timestamp: Date(),
            servingQuantity: 1.0,
            servingUnitName: unitName,
            baseCalories: item.calories,
            baseProteinGrams: item.proteinGrams,
            baseCarbsGrams: item.carbsGrams,
            baseFatGrams: item.fatGrams
        )
    }
}
