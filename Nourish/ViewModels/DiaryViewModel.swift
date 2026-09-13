import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class DiaryViewModel {
    var selectedDate: Date = Date()
    var currentLog: DailyLog?

    var isLoading: Bool = false
    var error: Error?

    func loadData(for date: Date, context: ModelContext) {
        self.selectedDate = date
        fetchLog(context: context)
    }

    func changeDate(byDays days: Int, context: ModelContext) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            loadData(for: newDate, context: context)
        }
    }

    private func fetchLog(context: ModelContext) {
        let dateString = DateFormatter.yyyyMMdd.string(from: selectedDate)

        let descriptor = FetchDescriptor<DailyLog>(predicate: #Predicate<DailyLog> { log in
            log.dateString == dateString
        })

        do {
            if let log = try context.fetch(descriptor).first {
                self.currentLog = log
            } else {
                let newLog = DailyLog(dateString: dateString)
                context.insert(newLog)
                try context.save()
                self.currentLog = newLog
            }
        } catch {
            self.error = error
        }
    }

    func deleteFoodItem(_ item: FoodItem, context: ModelContext) {
        context.delete(item)
        do {
            try context.save()
        } catch {
            self.error = error
        }
    }

    func items(for mealType: MealType) -> [FoodItem] {
        return currentLog?.foodItems(for: mealType) ?? []
    }

    func totalCalories(for mealType: MealType) -> Double {
        return items(for: mealType).reduce(0) { $0 + $1.calories }
    }
}
