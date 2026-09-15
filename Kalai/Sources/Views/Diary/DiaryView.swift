import SwiftUI
import SwiftData

struct DiaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var diaries: [DailyDiary]

    @State private var selectedDate: Date = .now
    @State private var activeMealType: String?

    var currentDiary: DailyDiary {
        if let existing = diaries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
            return existing
        } else {
            let newDiary = DailyDiary(date: selectedDate, foods: [])
            modelContext.insert(newDiary)
            return newDiary
        }
    }

    func foods(for mealType: String) -> [FoodRecord] {
        currentDiary.foods.filter { $0.mealType == mealType }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Date switcher
                    HStack {
                        Button {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(KalaiTheme.colors.accent)
                        }

                        Spacer()

                        Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.headline)
                            .foregroundStyle(KalaiTheme.colors.text)

                        Spacer()

                        Button {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                        } label: {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(KalaiTheme.colors.accent)
                        }
                    }
                    .padding()
                    .background(KalaiTheme.colors.surface)
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Daily summary ring
                    HStack(spacing: 20) {
                        MacroRingView(total: 2000, consumed: currentDiary.totalCalories)
                            .frame(width: 100, height: 100)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Total Logged")
                                .font(.caption)
                                .foregroundStyle(KalaiTheme.colors.accent)
                            Text("\(Int(currentDiary.totalCalories)) kcal")
                                .font(.title2.bold())
                                .foregroundStyle(KalaiTheme.colors.text)
                            Text("Goal: 2000 kcal")
                                .font(.caption)
                                .foregroundStyle(KalaiTheme.colors.text.opacity(0.8))
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KalaiTheme.colors.surface.opacity(0.3))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Meal Sections
                    VStack(spacing: 12) {
                        MealSectionView(title: "Breakfast", foods: foods(for: "Breakfast")) {
                            activeMealType = "Breakfast"
                        }
                        MealSectionView(title: "Lunch", foods: foods(for: "Lunch")) {
                            activeMealType = "Lunch"
                        }
                        MealSectionView(title: "Dinner", foods: foods(for: "Dinner")) {
                            activeMealType = "Dinner"
                        }
                        MealSectionView(title: "Snacks", foods: foods(for: "Snacks")) {
                            activeMealType = "Snacks"
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .kalaiBackground()
            .navigationTitle("Diary")
            .sheet(item: Binding(get: {
                activeMealType.map { MealTypeWrapper(type: $0) }
            }, set: {
                activeMealType = $0?.type
            })) { wrapper in
                FoodSearchView(mealType: wrapper.type, selectedDate: selectedDate) { newRecord in
                    currentDiary.foods.append(newRecord)
                    try? modelContext.save()
                }
            }
        }
    }
}

struct MealTypeWrapper: Identifiable {
    let id = UUID()
    let type: String
}
