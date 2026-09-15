import SwiftUI

struct MealSectionView: View {
    let title: String
    let foods: [FoodRecord]
    var onAddFood: () -> Void
    var onDeleteFood: ((FoodRecord) -> Void)?

    var totalCalories: Double {
        foods.reduce(0) { $0 + $1.calories }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(KalaiTheme.colors.text)
                Spacer()
                Text("\(Int(totalCalories)) kcal")
                    .font(.subheadline)
                    .foregroundStyle(KalaiTheme.colors.accent)
            }

            if !foods.isEmpty {
                VStack(spacing: 6) {
                    ForEach(foods) { food in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(food.name)
                                    .font(.subheadline)
                                    .foregroundStyle(KalaiTheme.colors.text)
                                Text("\(String(format: "%.1f", food.portionSize)) \(food.portionUnit)")
                                    .font(.caption2)
                                    .foregroundStyle(KalaiTheme.colors.accent)
                            }
                            Spacer()
                            Text("\(Int(food.calories))")
                                .font(.subheadline)
                                .foregroundStyle(KalaiTheme.colors.text)
                        }
                        .padding(.vertical, 4)
                        Divider().background(KalaiTheme.colors.surface)
                    }
                }
            }

            Button {
                onAddFood()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Food")
                }
                .font(.subheadline.bold())
                .foregroundStyle(KalaiTheme.colors.accent)
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(KalaiTheme.colors.surface.opacity(0.4))
        .cornerRadius(12)
    }
}
