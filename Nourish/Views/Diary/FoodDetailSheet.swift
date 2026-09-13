import SwiftUI
import SwiftData

struct FoodDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var foodItem: FoodItem
    var onDelete: (() -> Void)?

    @State private var isEditing: Bool = false
    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""
    @State private var mealType: MealType = .snack
    @State private var servingUnitName: String = "Serving"
    @State private var servingQuantity: Double = 1.0
    @State private var autoCalculateCalories: Bool = true

    init(foodItem: FoodItem, onDelete: (() -> Void)? = nil) {
        self.foodItem = foodItem
        self.onDelete = onDelete
        self._name = State(initialValue: foodItem.name)
        self._brand = State(initialValue: foodItem.brand ?? "")
        self._calories = State(initialValue: String(format: "%.0f", foodItem.baseCalories ?? (foodItem.servingQuantity != nil && foodItem.servingQuantity! > 0 ? foodItem.calories / foodItem.servingQuantity! : foodItem.calories)))
        self._protein = State(initialValue: String(format: "%.1f", foodItem.baseProteinGrams ?? (foodItem.servingQuantity != nil && foodItem.servingQuantity! > 0 ? foodItem.proteinGrams / foodItem.servingQuantity! : foodItem.proteinGrams)))
        self._carbs = State(initialValue: String(format: "%.1f", foodItem.baseCarbsGrams ?? (foodItem.servingQuantity != nil && foodItem.servingQuantity! > 0 ? foodItem.carbsGrams / foodItem.servingQuantity! : foodItem.carbsGrams)))
        self._fat = State(initialValue: String(format: "%.1f", foodItem.baseFatGrams ?? (foodItem.servingQuantity != nil && foodItem.servingQuantity! > 0 ? foodItem.fatGrams / foodItem.servingQuantity! : foodItem.fatGrams)))
        self._mealType = State(initialValue: foodItem.mealType)
        self._servingUnitName = State(initialValue: foodItem.servingUnitName ?? "Serving")
        self._servingQuantity = State(initialValue: foodItem.servingQuantity ?? 1.0)
    }

    var body: some View {
        NavigationStack {
            Group {
                if isEditing {
                    editForm
                } else {
                    detailView
                }
            }
            .navigationTitle(isEditing ? "Edit Food" : "Food Details")
            
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if isEditing {
                        Button("Cancel") {
                            isEditing = false
                        }
                    } else {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                        }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    } else {
                        Button("Edit") {
                            loadCurrentValues()
                            isEditing = true
                        }
                    }
                }
            }
        }
    }

    private var detailView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text(foodItem.name)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    if let brand = foodItem.brand, !brand.isEmpty {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: foodItem.mealType.iconName)
                            Text(foodItem.mealType.displayName)
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(ThemeColors.surfaceBackground)
                        .clipShape(Capsule())

                        if let qty = foodItem.servingQuantity, let unit = foodItem.servingUnitName {
                            HStack(spacing: 4) {
                                Image(systemName: "scalemass.fill")
                                Text(String(format: "%.1f %@", qty, unit))
                            }
                            .font(.caption.bold())
                            .foregroundColor(ThemeColors.protein)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(ThemeColors.surfaceBackground)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.top)

                // Calories Card
                FrostedCard {
                    VStack(spacing: 6) {
                        Text("\(Int(foodItem.calories))")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("Total Calories (kcal)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)

                // Macros
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        macroCard(title: "Protein", amount: foodItem.proteinGrams, color: ThemeColors.protein)
                        macroCard(title: "Carbs", amount: foodItem.carbsGrams, color: ThemeColors.carbs)
                        macroCard(title: "Fat", amount: foodItem.fatGrams, color: ThemeColors.fat)
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 20)

                // Delete Button
                Button(role: .destructive) {
                    deleteItem()
                } label: {
                    Label("Delete Food Entry", systemImage: "trash")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ThemeColors.surfaceBackground)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
    }

    private func macroCard(title: String, amount: Double, color: Color) -> some View {
        FrostedCard {
            VStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(String(format: "%.1fg", amount))
                    .font(.headline.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private var editForm: some View {
        Form {
            Section("Basic Information") {
                TextField("Food Name", text: $name)
                TextField("Brand", text: $brand)

                Picker("Meal", selection: $mealType) {
                    ForEach(MealType.allCases) { type in
                        Label(type.displayName, systemImage: type.iconName).tag(type)
                    }
                }
            }

            Section("Serving Size & Quantity") {
                Picker("Serving Unit", selection: $servingUnitName) {
                    ForEach(["Serving", "Scoop", "Katori", "Nos", "Piece", "Cup", "Tbsp", "Tsp", "Small", "Medium", "Large", "g", "ml"], id: \.self) { unit in
                        Text(unit).tag(unit)
                    }
                }

                HStack {
                    Text("Number of Servings")
                    Spacer()
                    TextField("1.0", value: $servingQuantity, format: .number)
                        .numericKeyboard()
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Stepper("", value: $servingQuantity, in: 0.1...100.0, step: 0.5)
                        .labelsHidden()
                }
            }

            Section {
                Toggle("Auto-calculate calories from macros", isOn: $autoCalculateCalories)

                HStack {
                    Text("Base Calories (per 1 \(servingUnitName.lowercased()))")
                    Spacer()
                    TextField("0", text: $calories)
                        .numericKeyboard()
                        .multilineTextAlignment(.trailing)
                        .disabled(autoCalculateCalories)
                        .foregroundColor(autoCalculateCalories ? .secondary : .primary)
                    Text("kcal").foregroundColor(.secondary)
                }

                HStack {
                    Circle().fill(ThemeColors.protein).frame(width: 8, height: 8)
                    Text("Protein")
                    Spacer()
                    TextField("0", text: $protein)
                        .numericKeyboard()
                        .multilineTextAlignment(.trailing)
                        .onChange(of: protein) { _, _ in
                            recalculateCalories()
                        }
                    Text("g").foregroundColor(.secondary)
                }

                HStack {
                    Circle().fill(ThemeColors.carbs).frame(width: 8, height: 8)
                    Text("Carbs")
                    Spacer()
                    TextField("0", text: $carbs)
                        .numericKeyboard()
                        .multilineTextAlignment(.trailing)
                        .onChange(of: carbs) { _, _ in
                            recalculateCalories()
                        }
                    Text("g").foregroundColor(.secondary)
                }

                HStack {
                    Circle().fill(ThemeColors.fat).frame(width: 8, height: 8)
                    Text("Fat")
                    Spacer()
                    TextField("0", text: $fat)
                        .numericKeyboard()
                        .multilineTextAlignment(.trailing)
                        .onChange(of: fat) { _, _ in
                            recalculateCalories()
                        }
                    Text("g").foregroundColor(.secondary)
                }
            } header: {
                Text("Nutrition (Per 1 \(servingUnitName))")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    if autoCalculateCalories {
                        Text("Base Calories = (Protein × 4) + (Carbs × 4) + (Fat × 9)")
                    }
                    if servingQuantity != 1.0 {
                        let totalCal = (Double(calories) ?? 0) * servingQuantity
                        let totalP = (Double(protein) ?? 0) * servingQuantity
                        let totalC = (Double(carbs) ?? 0) * servingQuantity
                        let totalF = (Double(fat) ?? 0) * servingQuantity
                        Text(String(format: "Total for %.1f %@: %.0f kcal (P: %.1fg, C: %.1fg, F: %.1fg)", servingQuantity, servingUnitName, totalCal, totalP, totalC, totalF))
                            .font(.footnote)
                            .foregroundColor(ThemeColors.protein)
                    }
                }
            }
        }
    }

    private func recalculateCalories() {
        guard autoCalculateCalories else { return }
        let p = Double(protein) ?? 0
        let c = Double(carbs) ?? 0
        let f = Double(fat) ?? 0
        let total = (p * 4.0) + (c * 4.0) + (f * 9.0)
        calories = String(format: "%.0f", total)
    }

    private func loadCurrentValues() {
        name = foodItem.name
        brand = foodItem.brand ?? ""
        servingQuantity = foodItem.servingQuantity ?? 1.0
        servingUnitName = foodItem.servingUnitName ?? "Serving"
        let baseCal = foodItem.baseCalories ?? (servingQuantity > 0 ? foodItem.calories / servingQuantity : foodItem.calories)
        let baseP = foodItem.baseProteinGrams ?? (servingQuantity > 0 ? foodItem.proteinGrams / servingQuantity : foodItem.proteinGrams)
        let baseC = foodItem.baseCarbsGrams ?? (servingQuantity > 0 ? foodItem.carbsGrams / servingQuantity : foodItem.carbsGrams)
        let baseF = foodItem.baseFatGrams ?? (servingQuantity > 0 ? foodItem.fatGrams / servingQuantity : foodItem.fatGrams)

        calories = String(format: "%.0f", baseCal)
        protein = String(format: "%.1f", baseP)
        carbs = String(format: "%.1f", baseC)
        fat = String(format: "%.1f", baseF)
        mealType = foodItem.mealType
    }

    private func saveChanges() {
        let baseCal = Double(calories) ?? 0
        let baseP = Double(protein) ?? 0
        let baseC = Double(carbs) ?? 0
        let baseF = Double(fat) ?? 0
        let qty = max(0.01, servingQuantity)

        foodItem.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        foodItem.brand = brand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : brand.trimmingCharacters(in: .whitespacesAndNewlines)
        foodItem.servingQuantity = qty
        foodItem.servingUnitName = servingUnitName
        foodItem.baseCalories = baseCal
        foodItem.baseProteinGrams = baseP
        foodItem.baseCarbsGrams = baseC
        foodItem.baseFatGrams = baseF
        foodItem.calories = baseCal * qty
        foodItem.proteinGrams = baseP * qty
        foodItem.carbsGrams = baseC * qty
        foodItem.fatGrams = baseF * qty
        foodItem.mealType = mealType

        try? modelContext.save()
        isEditing = false
    }

    private func deleteItem() {
        if let onDelete {
            onDelete()
        } else {
            modelContext.delete(foodItem)
            try? modelContext.save()
        }
        dismiss()
    }
}
