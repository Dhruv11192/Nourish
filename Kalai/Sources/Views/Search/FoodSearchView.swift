import SwiftUI
import SwiftData

struct FoodSearchView: View {
    let mealType: String
    let selectedDate: Date
    var onFoodLogged: (FoodRecord) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allFoods: [CatalogFoodEntry]

    @State private var searchText: String = ""
    @State private var selectedFood: CatalogFoodEntry?
    @State private var showScanner: Bool = false

    var filteredFoods: [CatalogFoodEntry] {
        if searchText.isEmpty {
            return allFoods
        } else {
            return allFoods.filter { $0.name.localizedStandardContains(searchText) || $0.brand.localizedStandardContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(KalaiTheme.colors.accent)
                    TextField("Search foods...", text: $searchText)
                        .foregroundStyle(KalaiTheme.colors.text)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(KalaiTheme.colors.surface)
                        }
                    }
                    Button {
                        showScanner = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                            .font(.title3)
                            .foregroundStyle(KalaiTheme.colors.accent)
                    }
                }
                .padding()
                .background(KalaiTheme.colors.surface)
                .cornerRadius(12)
                .padding(.horizontal)

                List {
                    ForEach(filteredFoods) { food in
                        Button {
                            selectedFood = food
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(food.name)
                                        .font(.headline)
                                        .foregroundStyle(KalaiTheme.colors.text)
                                    if !food.brand.isEmpty {
                                        Text(food.brand)
                                            .font(.caption)
                                            .foregroundStyle(KalaiTheme.colors.accent)
                                    }
                                }
                                Spacer()
                                Text("\(Int(food.calories)) kcal")
                                    .font(.subheadline)
                                    .foregroundStyle(KalaiTheme.colors.text)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(KalaiTheme.colors.surface.opacity(0.3))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .kalaiBackground()
            .navigationTitle("Add to \(mealType)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KalaiTheme.colors.accent)
                }
            }
            .sheet(item: $selectedFood) { food in
                FoodDetailModalView(food: food, mealType: mealType) { record in
                    onFoodLogged(record)
                    dismiss()
                }
            }
        }
    }
}
