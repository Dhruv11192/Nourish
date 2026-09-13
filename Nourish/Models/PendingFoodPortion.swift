import Foundation

struct PendingFoodPortion: Identifiable, Equatable {
    let id = UUID()
    let item: FoodItem
    
    static func == (lhs: PendingFoodPortion, rhs: PendingFoodPortion) -> Bool {
        lhs.id == rhs.id
    }
}
