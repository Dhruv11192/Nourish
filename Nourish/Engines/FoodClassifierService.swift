import Foundation
import Vision
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
typealias UIImage = NSImage
#endif

// MARK: - EstimatedFoodCandidate

struct EstimatedFoodCandidate: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var confidence: Double
    var servingGrams: Double
    var calories: Double
    var proteinGrams: Double
    var carbsGrams: Double
    var fatGrams: Double

    init(
        id: UUID = UUID(),
        name: String,
        confidence: Double,
        servingGrams: Double,
        calories: Double,
        proteinGrams: Double,
        carbsGrams: Double,
        fatGrams: Double
    ) {
        self.id = id
        self.name = name
        self.confidence = confidence
        self.servingGrams = servingGrams
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
    }

    func scaled(by multiplier: Double) -> EstimatedFoodCandidate {
        EstimatedFoodCandidate(
            id: self.id,
            name: self.name,
            confidence: self.confidence,
            servingGrams: self.servingGrams * multiplier,
            calories: self.calories * multiplier,
            proteinGrams: self.proteinGrams * multiplier,
            carbsGrams: self.carbsGrams * multiplier,
            fatGrams: self.fatGrams * multiplier
        )
    }

    func toFoodItem(mealType: MealType = .lunch) -> FoodItem {
        FoodItem(
            name: self.name,
            calories: self.calories,
            proteinGrams: self.proteinGrams,
            carbsGrams: self.carbsGrams,
            fatGrams: self.fatGrams,
            mealType: mealType
        )
    }
}

// MARK: - Error Types

enum FoodClassifierError: LocalizedError {
    case invalidImage
    case classificationFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Unable to process the image for food classification."
        case .classificationFailed(let reason):
            return "Food classification failed: \(reason)"
        }
    }
}

// MARK: - FoodClassifierProtocol

protocol FoodClassifierProtocol: Sendable {
    func classifyPlate(image: UIImage) async throws -> [EstimatedFoodCandidate]
    func classifyPlate(cgImage: CGImage) async throws -> [EstimatedFoodCandidate]
    func matchLabelsToFoods(_ labels: [(identifier: String, confidence: Float)]) -> [EstimatedFoodCandidate]
}

// MARK: - FoodClassifierService Implementation

final class FoodClassifierService: FoodClassifierProtocol {

    init() {}

    func classifyPlate(image: UIImage) async throws -> [EstimatedFoodCandidate] {
        #if canImport(UIKit)
        guard let cgImage = image.cgImage else {
            throw FoodClassifierError.invalidImage
        }
        #elseif canImport(AppKit)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw FoodClassifierError.invalidImage
        }
        #endif
        return try await classifyPlate(cgImage: cgImage)
    }

    func classifyPlate(cgImage: CGImage) async throws -> [EstimatedFoodCandidate] {
        try await Task.detached { [self] in
            let request = VNClassifyImageRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                throw FoodClassifierError.classificationFailed(error.localizedDescription)
            }

            guard let observations = request.results else {
                return []
            }

            let labels = observations.map { (identifier: $0.identifier, confidence: $0.confidence) }
            return self.matchLabelsToFoods(labels)
        }.value
    }

    func matchLabelsToFoods(_ labels: [(identifier: String, confidence: Float)]) -> [EstimatedFoodCandidate] {
        var matchedCandidatesByName: [String: (candidate: EstimatedFoodCandidate, confidence: Float)] = [:]

        for label in labels {
            // Check sub-labels first (comma/semicolon/slash separated)
            let subLabels = label.identifier
                .components(separatedBy: CharacterSet(charactersIn: ",;/"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            var matchedItem: LocalFoodItem? = nil

            for sub in subLabels {
                if let item = LocalFoodDatabase.find(matching: sub) {
                    matchedItem = item
                    break
                }
            }

            // Fallback to the whole identifier string
            if matchedItem == nil {
                matchedItem = LocalFoodDatabase.find(matching: label.identifier)
            }

            if let item = matchedItem {
                let candidate = EstimatedFoodCandidate(
                    name: item.name,
                    confidence: Double(label.confidence),
                    servingGrams: item.servingGrams,
                    calories: item.calories,
                    proteinGrams: item.proteinGrams,
                    carbsGrams: item.carbsGrams,
                    fatGrams: item.fatGrams
                )

                let existing = matchedCandidatesByName[item.name]
                if existing == nil || label.confidence > (existing?.confidence ?? 0) {
                    matchedCandidatesByName[item.name] = (candidate, label.confidence)
                }
            }
        }

        return matchedCandidatesByName.values
            .sorted { $0.confidence > $1.confidence }
            .map { $0.candidate }
    }
}
