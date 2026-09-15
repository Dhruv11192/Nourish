import Foundation

enum DataIngestor {
    static func parseFoods(from jsonData: Data) -> [CatalogFood] {
        guard let foods = try? JSONDecoder().decode([CatalogFood].self, from: jsonData) else {
            return []
        }
        return foods
    }
}
