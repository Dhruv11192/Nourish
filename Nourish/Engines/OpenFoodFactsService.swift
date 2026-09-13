import Foundation
import SwiftData

// MARK: - OpenFoodFacts Errors

enum OpenFoodFactsError: Error, LocalizedError, Equatable {
    case invalidBarcode
    case invalidURL
    case networkError(String)
    case productNotFound
    case decodingError(String)
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidBarcode: return "Invalid barcode format."
        case .invalidURL: return "Invalid server URL."
        case .networkError(let msg): return "Network error: \(msg)"
        case .productNotFound: return "Product not found."
        case .decodingError(let msg): return "Failed to decode response: \(msg)"
        case .serverError(let code): return "Server error with status code \(code)."
        }
    }
}

// MARK: - Service Protocol

protocol OpenFoodFactsServiceProtocol: AnyObject, Sendable {
    func fetchProduct(barcode: String) async throws -> FoodItem?
}

// MARK: - OpenFoodFacts Models (Internal)

struct OFFResponse: Decodable {
    let status: Int
    let product: OFFProduct?
}

struct OFFProduct: Decodable {
    let productName: String?
    let productNameEn: String?
    let brands: String?
    let nutriments: OFFNutriments?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case productNameEn = "product_name_en"
        case brands
        case nutriments
    }
}

struct OFFNutriments: Decodable {
    let energyKcal100g: Double?
    let energyKcalServing: Double?
    let proteins100g: Double?
    let proteinsServing: Double?
    let carbohydrates100g: Double?
    let carbohydratesServing: Double?
    let fat100g: Double?
    let fatServing: Double?
    let energy100g: Double? // in kJ

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case energyKcalServing = "energy-kcal_serving"
        case proteins100g = "proteins_100g"
        case proteinsServing = "proteins_serving"
        case carbohydrates100g = "carbohydrates_100g"
        case carbohydratesServing = "carbohydrates_serving"
        case fat100g = "fat_100g"
        case fatServing = "fat_serving"
        case energy100g = "energy_100g"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        func decodeFlexible(_ key: CodingKeys) -> Double? {
            if let val = try? container.decodeIfPresent(Double.self, forKey: key) { return val }
            if let valString = try? container.decodeIfPresent(String.self, forKey: key), let val = Double(valString) { return val }
            return nil
        }

        self.energyKcal100g = decodeFlexible(.energyKcal100g)
        self.energyKcalServing = decodeFlexible(.energyKcalServing)
        self.proteins100g = decodeFlexible(.proteins100g)
        self.proteinsServing = decodeFlexible(.proteinsServing)
        self.carbohydrates100g = decodeFlexible(.carbohydrates100g)
        self.carbohydratesServing = decodeFlexible(.carbohydratesServing)
        self.fat100g = decodeFlexible(.fat100g)
        self.fatServing = decodeFlexible(.fatServing)
        self.energy100g = decodeFlexible(.energy100g)
    }
}

// MARK: - OpenFoodFactsService

final class OpenFoodFactsService: OpenFoodFactsServiceProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchProduct(barcode: String) async throws -> FoodItem? {
        let sanitizedBarcode = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitizedBarcode.isEmpty else { throw OpenFoodFactsError.invalidBarcode }

        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(sanitizedBarcode).json") else {
            throw OpenFoodFactsError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Nourish - iOS - Version 1.0 - www.nourishapp.com", forHTTPHeaderField: "User-Agent")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw OpenFoodFactsError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenFoodFactsError.networkError("Invalid response type")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw OpenFoodFactsError.serverError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let result: OFFResponse
        do {
            result = try decoder.decode(OFFResponse.self, from: data)
        } catch {
            throw OpenFoodFactsError.decodingError(error.localizedDescription)
        }

        if result.status == 0 {
            throw OpenFoodFactsError.productNotFound
        }

        guard let product = result.product else {
            throw OpenFoodFactsError.productNotFound
        }

        // Mapping logic
        let nutriments = product.nutriments

        let calories = nutriments?.energyKcalServing ?? nutriments?.energyKcal100g ?? ((nutriments?.energy100g ?? 0.0) / 4.184)
        let protein = nutriments?.proteinsServing ?? nutriments?.proteins100g ?? 0.0
        let carbs = nutriments?.carbohydratesServing ?? nutriments?.carbohydrates100g ?? 0.0
        let fat = nutriments?.fatServing ?? nutriments?.fat100g ?? 0.0

        return FoodItem(
            name: product.productNameEn ?? product.productName ?? "Unknown Product",
            barcode: sanitizedBarcode,
            brand: product.brands,
            calories: calories,
            proteinGrams: protein,
            carbsGrams: carbs,
            fatGrams: fat
        )
    }
}
