import SwiftUI

struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    var initialMealType: MealType = .lunch
    var onSelectFood: ((FoodItem) -> Void)?

    @State private var searchText: String = ""
    @State private var selectedMealType: MealType = .lunch
    @State private var selectedCategory: String = "All"
    @State private var portionConfirmation: PendingFoodPortion?
    @State private var showManualCustomEntry: Bool = false

    private let categories = ["All", "Indian", "Protein", "Fruit", "Veggie", "Dairy", "Grain", "Snack"]

    init(
        initialMealType: MealType = .lunch,
        onSelectFood: ((FoodItem) -> Void)? = nil
    ) {
        self.initialMealType = initialMealType
        self._selectedMealType = State(initialValue: initialMealType)
        self.onSelectFood = onSelectFood
    }

    private var searchResults: [LocalFoodItem] {
        let baseResults = LocalFoodDatabase.search(query: searchText)
        if selectedCategory == "All" {
            return baseResults
        }
        return baseResults.filter { item in
            let lower = item.name.lowercased() + " " + item.keywords.joined(separator: " ").lowercased()
            switch selectedCategory {
            case "Indian":
                return lower.contains("roti") || lower.contains("paneer") || lower.contains("dal") || lower.contains("curry") || lower.contains("masala") || lower.contains("dosa") || lower.contains("idli") || lower.contains("biryani") || lower.contains("chawal") || lower.contains("sabzi") || lower.contains("paratha") || lower.contains("chilla") || lower.contains("bhurji") || lower.contains("pulao") || lower.contains("rajma") || lower.contains("chole")
            case "Protein":
                return lower.contains("chicken") || lower.contains("egg") || lower.contains("salmon") || lower.contains("beef") || lower.contains("tuna") || lower.contains("turkey") || lower.contains("whey") || lower.contains("protein") || lower.contains("tofu") || lower.contains("paneer") || item.proteinGrams >= 12
            case "Fruit":
                return lower.contains("banana") || lower.contains("apple") || lower.contains("berry") || lower.contains("berries") || lower.contains("orange") || lower.contains("mango") || lower.contains("grape") || lower.contains("watermelon") || lower.contains("lemon") || lower.contains("avocado")
            case "Veggie":
                return lower.contains("spinach") || lower.contains("broccoli") || lower.contains("salad") || lower.contains("onion") || lower.contains("tomato") || lower.contains("cucumber") || lower.contains("carrot") || lower.contains("pepper") || lower.contains("mushroom") || lower.contains("cauliflower")
            case "Dairy":
                return lower.contains("milk") || lower.contains("cheese") || lower.contains("yogurt") || lower.contains("curd") || lower.contains("butter") || lower.contains("cream") || lower.contains("ghee")
            case "Grain":
                return lower.contains("rice") || lower.contains("oat") || lower.contains("bread") || lower.contains("pasta") || lower.contains("roti") || lower.contains("flour") || lower.contains("quinoa") || lower.contains("wheat")
            case "Snack":
                return lower.contains("nut") || lower.contains("almond") || lower.contains("chocolate") || lower.contains("chip") || lower.contains("biscuit") || lower.contains("cookie") || lower.contains("bar") || lower.contains("popcorn")
            default:
                return true
            }
        }
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

                    // Quick Category Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { cat in
                                Button(action: {
                                    withAnimation(FluidSprings.standard) {
                                        selectedCategory = cat
                                    }
                                }) {
                                    Text(cat)
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(selectedCategory == cat ? ThemeColors.fat : ThemeColors.surfaceBackground)
                                        .foregroundColor(selectedCategory == cat ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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
