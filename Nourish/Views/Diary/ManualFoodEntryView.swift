import SwiftUI
import SwiftData

struct ManualFoodEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var initialMealType: MealType = .snack
    var onSave: ((FoodItem) -> Void)?

    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""
    @State private var mealType: MealType = .snack
    @State private var autoCalculateCalories: Bool = true

    init(initialMealType: MealType = .snack, onSave: ((FoodItem) -> Void)? = nil) {
        self.initialMealType = initialMealType
        self._mealType = State(initialValue: initialMealType)
        self.onSave = onSave
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

                Section {
                    Toggle("Auto-calculate calories from macros", isOn: $autoCalculateCalories)

                    HStack {
                        Text("Calories")
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
                    Text("Nutrition Details")
                } footer: {
                    if autoCalculateCalories {
                        Text("Calories = (Protein × 4) + (Carbs × 4) + (Fat × 9)")
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
        let cal = Double(calories) ?? 0
        let p = Double(protein) ?? 0
        let c = Double(carbs) ?? 0
        let f = Double(fat) ?? 0

        let item = FoodItem(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: brand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : brand.trimmingCharacters(in: .whitespacesAndNewlines),
            calories: cal,
            proteinGrams: p,
            carbsGrams: c,
            fatGrams: f,
            mealType: mealType,
            timestamp: Date()
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
