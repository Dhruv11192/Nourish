import Foundation

struct LocalFoodItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let keywords: [String]
    let servingGrams: Double
    let calories: Double
    let proteinGrams: Double
    let carbsGrams: Double
    let fatGrams: Double
    let servingDescription: String?

    init(
        id: UUID = UUID(),
        name: String,
        keywords: [String] = [],
        servingGrams: Double,
        calories: Double,
        proteinGrams: Double,
        carbsGrams: Double,
        fatGrams: Double,
        servingDescription: String? = nil
    ) {
        self.id = id
        self.name = name
        self.keywords = keywords
        self.servingGrams = servingGrams
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.servingDescription = servingDescription
    }
}

enum LocalFoodDatabase {
    private static let catalog: [LocalFoodItem] = [
        LocalFoodItem(
            name: "Chicken Breast",
            keywords: ["chicken", "chicken breast", "grilled chicken", "baked chicken", "poultry", "roasted chicken"],
            servingGrams: 100,
            calories: 165,
            proteinGrams: 31,
            carbsGrams: 0,
            fatGrams: 3.6,
            servingDescription: "100g"
        ),
        LocalFoodItem(
            name: "White Rice",
            keywords: ["white rice", "rice", "steamed rice", "jasmine rice", "basmati rice", "boiled rice"],
            servingGrams: 150,
            calories: 195,
            proteinGrams: 4,
            carbsGrams: 43,
            fatGrams: 0.4,
            servingDescription: "150g cooked"
        ),
        LocalFoodItem(
            name: "Brown Rice",
            keywords: ["brown rice", "wholegrain rice", "wild rice"],
            servingGrams: 150,
            calories: 165,
            proteinGrams: 3.5,
            carbsGrams: 35,
            fatGrams: 1.4,
            servingDescription: "150g cooked"
        ),
        LocalFoodItem(
            name: "Salmon",
            keywords: ["salmon", "grilled salmon", "baked salmon", "salmon fillet", "fish", "smoked salmon"],
            servingGrams: 120,
            calories: 250,
            proteinGrams: 26,
            carbsGrams: 0,
            fatGrams: 15,
            servingDescription: "120g fillet"
        ),
        LocalFoodItem(
            name: "Egg",
            keywords: ["egg", "boiled egg", "hard boiled egg", "fried egg", "scrambled egg", "poached egg", "eggs", "omelet", "omelette"],
            servingGrams: 50,
            calories: 74,
            proteinGrams: 6.3,
            carbsGrams: 0.4,
            fatGrams: 5,
            servingDescription: "1 large (50g)"
        ),
        LocalFoodItem(
            name: "Avocado",
            keywords: ["avocado", "guacamole", "avocado toast"],
            servingGrams: 100,
            calories: 160,
            proteinGrams: 2,
            carbsGrams: 8.5,
            fatGrams: 14.7,
            servingDescription: "100g"
        ),
        LocalFoodItem(
            name: "Banana",
            keywords: ["banana", "bananas"],
            servingGrams: 118,
            calories: 105,
            proteinGrams: 1.3,
            carbsGrams: 27,
            fatGrams: 0.3,
            servingDescription: "1 medium (118g)"
        ),
        LocalFoodItem(
            name: "Apple",
            keywords: ["apple", "red apple", "green apple", "apples"],
            servingGrams: 182,
            calories: 95,
            proteinGrams: 0.5,
            carbsGrams: 25,
            fatGrams: 0.3,
            servingDescription: "1 medium (182g)"
        ),
        LocalFoodItem(
            name: "Oatmeal",
            keywords: ["oatmeal", "porridge", "oats", "rolled oats", "steel cut oats"],
            servingGrams: 234,
            calories: 158,
            proteinGrams: 6,
            carbsGrams: 28,
            fatGrams: 3.2,
            servingDescription: "1 cup cooked (234g)"
        ),
        LocalFoodItem(
            name: "Broccoli",
            keywords: ["broccoli", "steamed broccoli", "roasted broccoli"],
            servingGrams: 91,
            calories: 31,
            proteinGrams: 2.6,
            carbsGrams: 6,
            fatGrams: 0.3,
            servingDescription: "1 cup (91g)"
        ),
        LocalFoodItem(
            name: "Steak",
            keywords: ["steak", "beef", "beef steak", "grilled steak", "sirloin", "ribeye", "filet mignon"],
            servingGrams: 150,
            calories: 375,
            proteinGrams: 38,
            carbsGrams: 0,
            fatGrams: 24,
            servingDescription: "150g"
        ),
        LocalFoodItem(
            name: "Greek Yogurt",
            keywords: ["greek yogurt", "yogurt", "plain greek yogurt", "yoghurt"],
            servingGrams: 170,
            calories: 100,
            proteinGrams: 17,
            carbsGrams: 6,
            fatGrams: 0.7,
            servingDescription: "170g"
        ),
        LocalFoodItem(
            name: "Sweet Potato",
            keywords: ["sweet potato", "baked sweet potato", "roasted sweet potato", "yam"],
            servingGrams: 130,
            calories: 112,
            proteinGrams: 2,
            carbsGrams: 26,
            fatGrams: 0.1,
            servingDescription: "130g"
        ),
        LocalFoodItem(
            name: "Pasta",
            keywords: ["pasta", "spaghetti", "penne", "fettuccine", "macaroni", "noodles"],
            servingGrams: 140,
            calories: 220,
            proteinGrams: 8,
            carbsGrams: 43,
            fatGrams: 1.3,
            servingDescription: "140g cooked"
        ),
        LocalFoodItem(
            name: "Pizza",
            keywords: ["pizza", "pepperoni pizza", "cheese pizza", "pizza slice", "margherita pizza"],
            servingGrams: 107,
            calories: 285,
            proteinGrams: 12,
            carbsGrams: 36,
            fatGrams: 10,
            servingDescription: "1 slice (107g)"
        ),
        LocalFoodItem(
            name: "Salad",
            keywords: ["salad", "garden salad", "green salad", "mixed greens", "caesar salad"],
            servingGrams: 150,
            calories: 45,
            proteinGrams: 2,
            carbsGrams: 8,
            fatGrams: 1,
            servingDescription: "150g"
        ),
        LocalFoodItem(
            name: "Tofu",
            keywords: ["tofu", "firm tofu", "fried tofu", "bean curd"],
            servingGrams: 100,
            calories: 76,
            proteinGrams: 8,
            carbsGrams: 1.9,
            fatGrams: 4.8,
            servingDescription: "100g"
        ),
        LocalFoodItem(
            name: "Almonds",
            keywords: ["almonds", "almond", "nuts", "mixed nuts", "roasted almonds"],
            servingGrams: 28,
            calories: 164,
            proteinGrams: 6,
            carbsGrams: 6,
            fatGrams: 14,
            servingDescription: "1 oz (28g)"
        ),
        LocalFoodItem(
            name: "Burger",
            keywords: ["burger", "cheeseburger", "hamburger", "beef burger"],
            servingGrams: 150,
            calories: 350,
            proteinGrams: 20,
            carbsGrams: 31,
            fatGrams: 16,
            servingDescription: "150g"
        ),
        LocalFoodItem(
            name: "Bread",
            keywords: ["bread", "toast", "white bread", "wheat bread", "whole wheat bread", "sourdough"],
            servingGrams: 35,
            calories: 80,
            proteinGrams: 3,
            carbsGrams: 15,
            fatGrams: 1,
            servingDescription: "1 slice (35g)"
        ),
        LocalFoodItem(
            name: "Peanut Butter",
            keywords: ["peanut butter", "pb", "nut butter", "smooth peanut butter"],
            servingGrams: 32,
            calories: 188,
            proteinGrams: 8,
            carbsGrams: 7,
            fatGrams: 16,
            servingDescription: "2 tbsp (32g)"
        ),
        LocalFoodItem(
            name: "Spinach",
            keywords: ["spinach", "baby spinach", "cooked spinach", "steamed spinach"],
            servingGrams: 100,
            calories: 23,
            proteinGrams: 2.9,
            carbsGrams: 3.6,
            fatGrams: 0.4,
            servingDescription: "100g"
        ),
        LocalFoodItem(
            name: "Protein Shake",
            keywords: ["protein shake", "protein powder", "whey protein", "protein drink"],
            servingGrams: 300,
            calories: 160,
            proteinGrams: 30,
            carbsGrams: 4,
            fatGrams: 2.5,
            servingDescription: "300g"
        ),
        LocalFoodItem(
            name: "Tuna",
            keywords: ["tuna", "canned tuna", "tuna fish", "tuna steak", "albacore"],
            servingGrams: 100,
            calories: 130,
            proteinGrams: 29,
            carbsGrams: 0,
            fatGrams: 1,
            servingDescription: "100g"
        ),
        LocalFoodItem(
            name: "Potato",
            keywords: ["potato", "baked potato", "boiled potato", "mashed potato", "french fries", "potatoes"],
            servingGrams: 150,
            calories: 140,
            proteinGrams: 3,
            carbsGrams: 32,
            fatGrams: 0.2,
            servingDescription: "150g"
        ),
        LocalFoodItem(
            name: "Cheddar Cheese",
            keywords: ["cheddar cheese", "cheese", "cheddar", "mozzarella", "swiss cheese"],
            servingGrams: 30,
            calories: 120,
            proteinGrams: 7,
            carbsGrams: 0.4,
            fatGrams: 10,
            servingDescription: "30g"
        ),
        LocalFoodItem(
            name: "Milk",
            keywords: ["milk", "whole milk", "dairy milk", "cow milk", "skim milk", "low fat milk"],
            servingGrams: 244,
            calories: 150,
            proteinGrams: 8,
            carbsGrams: 12,
            fatGrams: 8,
            servingDescription: "1 cup (244g)"
        ),
        LocalFoodItem(
            name: "Blueberry",
            keywords: ["blueberry", "blueberries", "fresh blueberries", "wild blueberries"],
            servingGrams: 100,
            calories: 57,
            proteinGrams: 0.7,
            carbsGrams: 14.5,
            fatGrams: 0.3,
            servingDescription: "100g"
        ),
        LocalFoodItem(
            name: "Strawberry",
            keywords: ["strawberry", "strawberries", "fresh strawberries"],
            servingGrams: 100,
            calories: 32,
            proteinGrams: 0.7,
            carbsGrams: 7.7,
            fatGrams: 0.3,
            servingDescription: "100g"
        ),
        LocalFoodItem(
            name: "Orange",
            keywords: ["orange", "oranges", "clementine", "mandarin", "citrus"],
            servingGrams: 131,
            calories: 62,
            proteinGrams: 1.2,
            carbsGrams: 15.4,
            fatGrams: 0.2,
            servingDescription: "1 medium (131g)"
        ),
        LocalFoodItem(
            name: "Turkey Breast",
            keywords: ["turkey", "turkey breast", "ground turkey", "roasted turkey", "deli turkey"],
            servingGrams: 100,
            calories: 135,
            proteinGrams: 30,
            carbsGrams: 0,
            fatGrams: 1,
            servingDescription: "100g"
        ),
        LocalFoodItem(
            name: "Pork Chop",
            keywords: ["pork chop", "pork", "pork loin", "grilled pork", "roasted pork"],
            servingGrams: 120,
            calories: 260,
            proteinGrams: 26,
            carbsGrams: 0,
            fatGrams: 17,
            servingDescription: "120g"
        ),
        LocalFoodItem(
            name: "Soup",
            keywords: ["soup", "chicken soup", "vegetable soup", "broth", "noodle soup", "tomato soup"],
            servingGrams: 240,
            calories: 75,
            proteinGrams: 4,
            carbsGrams: 9,
            fatGrams: 2.5,
            servingDescription: "1 cup (240g)"
        ),
        LocalFoodItem(
            name: "Shrimp",
            keywords: ["shrimp", "grilled shrimp", "prawn", "prawns", "boiled shrimp"],
            servingGrams: 100,
            calories: 99,
            proteinGrams: 24,
            carbsGrams: 0.2,
            fatGrams: 0.3,
            servingDescription: "100g"
        ),
        LocalFoodItem(
            name: "Hummus",
            keywords: ["hummus", "chickpea dip", "houmous"],
            servingGrams: 30,
            calories: 50,
            proteinGrams: 2,
            carbsGrams: 4,
            fatGrams: 3,
            servingDescription: "2 tbsp (30g)"
        ),
        LocalFoodItem(
            name: "Rice Cake",
            keywords: ["rice cake", "rice cakes", "puffed rice"],
            servingGrams: 28,
            calories: 105,
            proteinGrams: 2.2,
            carbsGrams: 23,
            fatGrams: 0.8,
            servingDescription: "3 cakes (28g)"
        ),
        LocalFoodItem(
            name: "Dark Chocolate",
            keywords: ["dark chocolate", "chocolate", "cocoa"],
            servingGrams: 30,
            calories: 170,
            proteinGrams: 2.2,
            carbsGrams: 13,
            fatGrams: 12,
            servingDescription: "30g"
        )
    ]

    public static func allItems() -> [LocalFoodItem] {
        return catalog
    }

    public static func find(matching query: String) -> LocalFoodItem? {
        let cleaned = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !cleaned.isEmpty else { return nil }

        // 1. Exact item name match
        if let exactName = catalog.first(where: { $0.name.lowercased() == cleaned }) {
            return exactName
        }

        // 2. Exact keyword match
        if let exactKeyword = catalog.first(where: { item in
            item.keywords.contains { $0.lowercased() == cleaned }
        }) {
            return exactKeyword
        }

        // 3. Name containment
        if let nameContains = catalog.first(where: { item in
            let lowerName = item.name.lowercased()
            return cleaned.contains(lowerName) || lowerName.contains(cleaned)
        }) {
            return nameContains
        }

        // 4. Keyword containment - prioritize longest keyword match
        var bestKeywordMatch: (item: LocalFoodItem, length: Int)? = nil
        for item in catalog {
            for kw in item.keywords {
                let kwLower = kw.lowercased()
                if cleaned.contains(kwLower) || kwLower.contains(cleaned) {
                    let length = kwLower.count
                    if bestKeywordMatch == nil || length > (bestKeywordMatch?.length ?? 0) {
                        bestKeywordMatch = (item, length)
                    }
                }
            }
        }
        if let match = bestKeywordMatch?.item {
            return match
        }

        // 5. Tokenized word overlap matching
        let ignoredWords: Set<String> = [
            "a", "an", "the", "of", "and", "with", "plate", "dish", "bowl", "food",
            "cup", "slice", "serving", "item", "fresh", "cooked", "raw", "prepared",
            "wooden", "table", "chair", "desk", "background", "furniture"
        ]

        let tokens = cleaned
            .split { !$0.isLetter && !$0.isNumber }
            .map { String($0) }
            .filter { !ignoredWords.contains($0) && $0.count >= 3 }

        guard !tokens.isEmpty else { return nil }

        var bestTokenScore = 0
        var bestTokenItem: LocalFoodItem? = nil

        for item in catalog {
            var score = 0
            let itemNameLower = item.name.lowercased()
            let allKeywords = item.keywords.map { $0.lowercased() }

            for token in tokens {
                if itemNameLower.contains(token) {
                    score += 3
                }
                for kw in allKeywords {
                    if kw.contains(token) {
                        score += 2
                    }
                }
            }

            if score > bestTokenScore {
                bestTokenScore = score
                bestTokenItem = item
            }
        }

        if bestTokenScore > 0 {
            return bestTokenItem
        }

        return nil
    }
}
