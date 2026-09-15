import SwiftUI

struct FoodDetailModalView: View {
    let food: CatalogFoodEntry
    let mealType: String
    var onLog: (FoodRecord) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var servings: Double = 1.0

    func calculatedCalories(servings: Double) -> Double {
        return food.calories * servings
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.title2.bold())
                        .foregroundStyle(KalaiTheme.colors.text)
                    if !food.brand.isEmpty {
                        Text(food.brand)
                            .font(.subheadline)
                            .foregroundStyle(KalaiTheme.colors.accent)
                    }
                }

                HStack {
                    Text("Servings")
                        .foregroundStyle(KalaiTheme.colors.text)
                    Spacer()
                    TextField("1.0", value: $servings, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .padding(8)
                        .background(KalaiTheme.colors.surface)
                        .cornerRadius(8)
                        .foregroundStyle(KalaiTheme.colors.text)
                        .frame(width: 80)
                }

                VStack(spacing: 12) {
                    HStack {
                        Text("Calories")
                        Spacer()
                        Text("\(Int(calculatedCalories(servings: servings))) kcal")
                    }
                    Divider().background(KalaiTheme.colors.surface)
                    HStack {
                        Text("Protein")
                        Spacer()
                        Text(String(format: "%.1f g", food.protein * servings))
                    }
                    Divider().background(KalaiTheme.colors.surface)
                    HStack {
                        Text("Carbohydrates")
                        Spacer()
                        Text(String(format: "%.1f g", food.carbs * servings))
                    }
                    Divider().background(KalaiTheme.colors.surface)
                    HStack {
                        Text("Fat")
                        Spacer()
                        Text(String(format: "%.1f g", food.fat * servings))
                    }
                }
                .padding()
                .background(KalaiTheme.colors.surface.opacity(0.5))
                .cornerRadius(12)
                .foregroundStyle(KalaiTheme.colors.text)

                Spacer()

                Button {
                    let record = FoodRecord(
                        name: food.name,
                        brand: food.brand,
                        calories: calculatedCalories(servings: servings),
                        protein: food.protein * servings,
                        carbs: food.carbs * servings,
                        fat: food.fat * servings,
                        portionSize: servings,
                        portionUnit: food.servingUnit,
                        mealType: mealType
                    )
                    onLog(record)
                    dismiss()
                } label: {
                    Text("Log to \(mealType)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(KalaiTheme.colors.accent)
                        .foregroundStyle(KalaiTheme.colors.background)
                        .cornerRadius(12)
                }
            }
            .padding()
            .kalaiBackground()
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(KalaiTheme.colors.accent)
                }
            }
        }
    }
}
