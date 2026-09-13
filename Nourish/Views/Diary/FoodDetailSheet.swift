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

    init(foodItem: FoodItem, onDelete: (() -> Void)? = nil) {
        self.foodItem = foodItem
        self.onDelete = onDelete
        self._name = State(initialValue: foodItem.name)
        self._brand = State(initialValue: foodItem.brand ?? "")
        self._calories = State(initialValue: String(format: "%.0f", foodItem.calories))
        self._protein = State(initialValue: String(format: "%.1f", foodItem.proteinGrams))
        self._carbs = State(initialValue: String(format: "%.1f", foodItem.carbsGrams))
        self._fat = State(initialValue: String(format: "%.1f", foodItem.fatGrams))
        self._mealType = State(initialValue: foodItem.mealType)
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

                    HStack(spacing: 6) {
                        Image(systemName: foodItem.mealType.iconName)
                        Text(foodItem.mealType.displayName)
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(ThemeColors.surfaceBackground)
                    .clipShape(Capsule())
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

            Section("Nutrition") {
                HStack {
                    Text("Calories")
                    Spacer()
                    TextField("0", text: $calories)
                        .numericKeyboard()
                        .multilineTextAlignment(.trailing)
                    Text("kcal").foregroundColor(.secondary)
                }

                HStack {
                    Text("Protein")
                    Spacer()
                    TextField("0", text: $protein)
                        .numericKeyboard()
                        .multilineTextAlignment(.trailing)
                    Text("g").foregroundColor(.secondary)
                }

                HStack {
                    Text("Carbs")
                    Spacer()
                    TextField("0", text: $carbs)
                        .numericKeyboard()
                        .multilineTextAlignment(.trailing)
                    Text("g").foregroundColor(.secondary)
                }

                HStack {
                    Text("Fat")
                    Spacer()
                    TextField("0", text: $fat)
                        .numericKeyboard()
                        .multilineTextAlignment(.trailing)
                    Text("g").foregroundColor(.secondary)
                }
            }
        }
    }

    private func loadCurrentValues() {
        name = foodItem.name
        brand = foodItem.brand ?? ""
        calories = String(format: "%.0f", foodItem.calories)
        protein = String(format: "%.1f", foodItem.proteinGrams)
        carbs = String(format: "%.1f", foodItem.carbsGrams)
        fat = String(format: "%.1f", foodItem.fatGrams)
        mealType = foodItem.mealType
    }

    private func saveChanges() {
        foodItem.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        foodItem.brand = brand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : brand.trimmingCharacters(in: .whitespacesAndNewlines)
        foodItem.calories = Double(calories) ?? 0
        foodItem.proteinGrams = Double(protein) ?? 0
        foodItem.carbsGrams = Double(carbs) ?? 0
        foodItem.fatGrams = Double(fat) ?? 0
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
