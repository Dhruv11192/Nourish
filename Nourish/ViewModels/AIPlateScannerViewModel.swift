import Foundation
import Observation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Observable
final class AIPlateScannerViewModel {
    enum ScanState: Equatable, Sendable {
        case idle
        case capturing
        case analyzing
        case results([EstimatedFoodCandidate])
        case empty
        case failed(String)
    }

    var state: ScanState = .idle
    var selectedCandidates: Set<UUID> = []
    var portionMultiplier: Double = 1.0
    var selectedMealType: MealType = .lunch

    private let classifierService: FoodClassifierProtocol

    init(classifierService: FoodClassifierProtocol = FoodClassifierService(), selectedMealType: MealType = .lunch) {
        self.classifierService = classifierService
        self.selectedMealType = selectedMealType
    }

    func analyzeImage(_ image: UIImage) async {
        state = .analyzing
        do {
            let candidates = try await classifierService.classifyPlate(image: image)
            if candidates.isEmpty {
                state = .empty
            } else {
                state = .results(candidates)
                // Select all candidates by default
                self.selectedCandidates = Set(candidates.map { $0.id })
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func toggleSelection(for candidateId: UUID) {
        if selectedCandidates.contains(candidateId) {
            selectedCandidates.remove(candidateId)
        } else {
            selectedCandidates.insert(candidateId)
        }
    }

    func generateFoodItemsToLog() -> [FoodItem] {
        guard case .results(let candidates) = state else { return [] }

        return candidates
            .filter { selectedCandidates.contains($0.id) }
            .map { candidate in
                candidate.scaled(by: portionMultiplier).toFoodItem(mealType: selectedMealType)
            }
    }

    func reset() {
        state = .idle
        selectedCandidates = []
        portionMultiplier = 1.0
    }
}
