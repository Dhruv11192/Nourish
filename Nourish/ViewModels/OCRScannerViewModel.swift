import Foundation
import Observation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
@Observable
final class OCRScannerViewModel {
    enum ScanState: Equatable, Sendable {
        case idle
        case scanning
        case recognized(ParsedNutritionData)
        case failed(String)
    }

    var state: ScanState = .idle
    var recognizedLines: [String] = []
    var parsedData: ParsedNutritionData? = nil
    var nameInput: String = ""
    var selectedMealType: MealType = .snack

    init() {}

    func processRecognizedLines(_ lines: [String]) {
        self.recognizedLines = lines
        let data = NutritionOCRParser.parseNutritionFacts(from: lines)
        if data.isValid {
            self.parsedData = data
            self.state = .recognized(data)
        } else {
            self.parsedData = nil
            self.state = .failed("No nutrition facts recognized")
        }
    }

    func processImage(_ image: UIImage) async {
        state = .scanning
        do {
            guard let cgImage = image.cgImage else {
                state = .failed("Invalid image")
                return
            }

            let lines = try await Task.detached {
                try NutritionOCRParser.recognizeText(from: cgImage)
            }.value

            processRecognizedLines(lines)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func createFoodItem() -> FoodItem? {
        guard let parsedData, parsedData.isValid else { return nil }
        let trimmedName = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmedName.isEmpty ? "Scanned Food" : trimmedName
        return parsedData.toFoodItem(name: name, mealType: selectedMealType)
    }

    func reset() {
        state = .idle
        recognizedLines = []
        parsedData = nil
        nameInput = ""
        selectedMealType = .snack
    }
}
