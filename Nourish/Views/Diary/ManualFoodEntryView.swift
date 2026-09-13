import SwiftUI
import SwiftData

struct ManualFoodEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var prefilledItem: FoodItem?
    var onSave: ((FoodItem) -> Void)?

    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""
    @State private var mealType: MealType = .snack
    @State private var autoCalculateCalories: Bool = true
    @State private var servingUnit: ServingUnit = .serving
    @State private var quantity: Double = 1.0

    // Pre-defined serving units
    enum ServingUnit: String, CaseIterable, Identifiable {
        case serving = "Serving"
        case scoop = "Scoop"
        case katori = "Katori"
        case nos = "Nos"
        case piece = "Piece"
        case bowl = "Bowl"
        case plate = "Plate"
        case slice = "Slice"
        case cup = "Cup"
        case tbsp = "Tbsp"
        case tsp = "Tsp"
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
        case oz = "oz"
        case ml = "ml"
        case g = "g"

        var id: String { rawValue }

        var displayName: String { rawValue }
    }

    init(prefilledItem: FoodItem? = nil, initialMealType: MealType = .snack, onSave: ((FoodItem) -> Void)? = nil) {
        self.prefilledItem = prefilledItem
        self.onSave = onSave

        let initialMealType = prefilledItem?.mealType ?? initialMealType
        self._mealType = State(initialValue: initialMealType)

        if let item = prefilledItem {
            self._name = State(initialValue: item.name)
            self._brand = State(initialValue: item.brand ?? "")
            let q = item.servingQuantity ?? 1.0
            self._quantity = State(initialValue: q)
            self._servingUnit = State(initialValue: ServingUnit(rawValue: item.servingUnitName ?? "Serving") ?? .serving)

            let baseCal = item.baseCalories ?? (q > 0 ? item.calories / q : item.calories)
            let baseP = item.baseProteinGrams ?? (q > 0 ? item.proteinGrams / q : item.proteinGrams)
            let baseC = item.baseCarbsGrams ?? (q > 0 ? item.carbsGrams / q : item.carbsGrams)
            let baseF = item.baseFatGrams ?? (q > 0 ? item.fatGrams / q : item.fatGrams)

            self._calories = State(initialValue: String(format: "%.0f", baseCal))
            self._protein = State(initialValue: String(format: "%.1f", baseP))
            self._carbs = State(initialValue: String(format: "%.1f", baseC))
            self._fat = State(initialValue: String(format: "%.1f", baseF))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Food Name (e.g., Greek Yogurt)", text: $name)
                    TextField("Brand (Optional)", text: $brand)

                    Picker("Meal", selection: $mealType) {
                        ForEach(MealType.allCases) { type in
                            Label(type.displayName, systemImage: type.iconName).tag(type)
                        }
                    }
                }

                Section("Serving Size & Quantity") {
                    Picker("Serving Unit", selection: $servingUnit) {
                        ForEach(ServingUnit.allCases) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }

                    HStack {
                        Text("Number of Servings")
                        Spacer()
                        TextField("1.0", value: $quantity, format: .number)
                            .numericKeyboard()
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Stepper("", value: $quantity, in: 0.1...100.0, step: 0.5)
                            .labelsHidden()
                    }
                }

                Section {
                    Toggle("Auto-calculate calories from macros", isOn: $autoCalculateCalories)

                    HStack {
                        Text("Calories (per \(servingUnit.displayName.lowercased()))")
                        Spacer()
                        TextField("0", text: $calories)
                            .numericKeyboard()
                            .multilineTextAlignment(.trailing)
                            .disabled(autoCalculateCalories)
                            .foregroundColor(autoCalculateCalories ? .secondary : .primary)
                        Text("kcal")
                            .foregroundColor(.secondary)
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
                        Text("g")
                            .foregroundColor(.secondary)
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
                        Text("g")
                            .foregroundColor(.secondary)
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
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Nutrition (Per 1 \(servingUnit.displayName))")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        if autoCalculateCalories {
                            Text("Base Calories = (Protein × 4) + (Carbs × 4) + (Fat × 9)")
                        }
                        if quantity != 1.0 {
                            let totalCal = (Double(calories) ?? 0) * quantity
                            let totalP = (Double(protein) ?? 0) * quantity
                            let totalC = (Double(carbs) ?? 0) * quantity
                            let totalF = (Double(fat) ?? 0) * quantity
                            Text(String(format: "Total for %.1f %@: %.0f kcal (P: %.1fg, C: %.1fg, F: %.1fg)", quantity, servingUnit.displayName, totalCal, totalP, totalC, totalF))
                                .font(.footnote)
                                .foregroundColor(ThemeColors.protein)
                        }
                    }
                }
            }
            .navigationTitle("Add Food")

            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveFood()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

    private func saveFood() {
        let baseCal = Double(calories) ?? 0
        let baseP = Double(protein) ?? 0
        let baseC = Double(carbs) ?? 0
        let baseF = Double(fat) ?? 0
        let qty = max(0.01, quantity)

        let item = FoodItem(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: brand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : brand.trimmingCharacters(in: .whitespacesAndNewlines),
            calories: baseCal * qty,
            proteinGrams: baseP * qty,
            carbsGrams: baseC * qty,
            fatGrams: baseF * qty,
            mealType: mealType,
            timestamp: Date(),
            servingQuantity: qty,
            servingUnitName: servingUnit.displayName,
            baseCalories: baseCal,
            baseProteinGrams: baseP,
            baseCarbsGrams: baseC,
            baseFatGrams: baseF
        )

        if let onSave {
            onSave(item)
        } else {
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
        }

        dismiss()
    }
}
