import Foundation
import SwiftUI
import SwiftData

// MARK: - Scanner State

enum ScannerState: Equatable {
    case idle
    case scanning
    case fetching(barcode: String)
    case success(FoodItem)
    case error(String)

    static func == (lhs: ScannerState, rhs: ScannerState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.scanning, .scanning):
            return true
        case (.fetching(let lCode), .fetching(let rCode)):
            return lCode == rCode
        case (.success(let lItem), .success(let rItem)):
            return lItem.name == rItem.name &&
                   lItem.barcode == rItem.barcode &&
                   lItem.calories == rItem.calories
        case (.error(let lMsg), .error(let rMsg)):
            return lMsg == rMsg
        default:
            return false
        }
    }
}

@MainActor
@Observable
final class BarcodeScannerViewModel {
    var state: ScannerState = .idle
    var scannedFoodItem: FoodItem? = nil
    var errorMessage: String? = nil

    var isScanning: Bool {
        if case .scanning = state { return true }
        return false
    }

    var isLoading: Bool {
        if case .fetching = state { return true }
        return false
    }

    private let service: OpenFoodFactsServiceProtocol

    init(service: OpenFoodFactsServiceProtocol = OpenFoodFactsService()) {
        self.service = service
    }

    func startScanning() {
        state = .scanning
        errorMessage = nil
    }

    func pauseScanning() {
        state = .idle
    }

    func reset() {
        state = .scanning
        scannedFoodItem = nil
        errorMessage = nil
    }

    func processScannedBarcode(_ barcode: String) async {
        let sanitizedBarcode = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitizedBarcode.isEmpty else {
            state = .error("Invalid barcode")
            errorMessage = "Invalid barcode"
            return
        }

        // Duplicate suppression
        if case .fetching(let currentBarcode) = state, currentBarcode == sanitizedBarcode { return }
        if case .success(let item) = state, item.barcode == sanitizedBarcode { return }

        state = .fetching(barcode: sanitizedBarcode)
        errorMessage = nil

        do {
            if let foodItem = try await service.fetchProduct(barcode: sanitizedBarcode) {
                scannedFoodItem = foodItem
                state = .success(foodItem)
            } else {
                throw OpenFoodFactsError.productNotFound
            }
        } catch let error as OpenFoodFactsError {
            state = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
        } catch {
            state = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }
}
