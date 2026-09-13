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

struct MFPFoodEntry: Codable {
    let name: String
    let calories: Double
    let proteinGrams: Double
    let carbsGrams: Double
    let fatGrams: Double
    let servingGrams: Double
    let defaultServingUnit: String?
    let defaultServingQuantity: Double?
    let multiplier: Double?
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
        ),
        LocalFoodItem(
            name: "Roti",
            keywords: ["roti", "chapati", "phulka", "indian bread", "flatbread", "wheat roti", "rotis"],
            servingGrams: 40,
            calories: 104,
            proteinGrams: 3.1,
            carbsGrams: 20,
            fatGrams: 0.5,
            servingDescription: "1 Piece (40g)"
        ),
        LocalFoodItem(
            name: "Dal Tadka",
            keywords: ["dal", "dal tadka", "yellow dal", "toor dal", "moong dal", "lentil soup", "daal", "dhal", "tadka dal"],
            servingGrams: 150,
            calories: 150,
            proteinGrams: 8,
            carbsGrams: 20,
            fatGrams: 4.5,
            servingDescription: "1 Katori (150g)"
        ),
        LocalFoodItem(
            name: "Paneer Butter Masala",
            keywords: ["paneer butter masala", "paneer makhani", "paneer", "cottage cheese curry", "shahi paneer", "paneer tikka masala"],
            servingGrams: 180,
            calories: 320,
            proteinGrams: 10,
            carbsGrams: 12,
            fatGrams: 26,
            servingDescription: "1 Katori (180g)"
        ),
        LocalFoodItem(
            name: "Palak Paneer",
            keywords: ["palak paneer", "saag paneer", "spinach paneer", "cottage cheese spinach"],
            servingGrams: 180,
            calories: 240,
            proteinGrams: 12,
            carbsGrams: 8,
            fatGrams: 18,
            servingDescription: "1 Katori (180g)"
        ),
        LocalFoodItem(
            name: "Chicken Biryani",
            keywords: ["biryani", "chicken biryani", "dum biryani", "hyderabadi biryani", "biriyani"],
            servingGrams: 250,
            calories: 450,
            proteinGrams: 28,
            carbsGrams: 52,
            fatGrams: 14,
            servingDescription: "1 Plate (250g)"
        ),
        LocalFoodItem(
            name: "Chole",
            keywords: ["chole", "chana masala", "chickpea curry", "chole masala", "kabuli chana", "chickpeas"],
            servingGrams: 180,
            calories: 220,
            proteinGrams: 10,
            carbsGrams: 32,
            fatGrams: 6,
            servingDescription: "1 Katori (180g)"
        ),
        LocalFoodItem(
            name: "Rajma",
            keywords: ["rajma", "kidney bean curry", "rajma masala", "rajma chawal"],
            servingGrams: 180,
            calories: 210,
            proteinGrams: 9,
            carbsGrams: 30,
            fatGrams: 5,
            servingDescription: "1 Katori (180g)"
        ),
        LocalFoodItem(
            name: "Idli",
            keywords: ["idli", "idlis", "steamed rice cake", "south indian idli", "sambhar idli"],
            servingGrams: 70,
            calories: 130,
            proteinGrams: 4,
            carbsGrams: 26,
            fatGrams: 0.4,
            servingDescription: "2 Pieces (70g)"
        ),
        LocalFoodItem(
            name: "Dosa",
            keywords: ["dosa", "plain dosa", "masala dosa", "crispy dosa", "south indian crepe"],
            servingGrams: 100,
            calories: 170,
            proteinGrams: 4,
            carbsGrams: 29,
            fatGrams: 4.5,
            servingDescription: "1 Piece (100g)"
        ),
        LocalFoodItem(
            name: "Poha",
            keywords: ["poha", "flattened rice", "kanda poha", "batata poha", "aval"],
            servingGrams: 150,
            calories: 230,
            proteinGrams: 4.5,
            carbsGrams: 38,
            fatGrams: 7,
            servingDescription: "1 Plate (150g)"
        ),
        LocalFoodItem(
            name: "Upma",
            keywords: ["upma", "rava upma", "sooji upma", "semolina upma"],
            servingGrams: 150,
            calories: 210,
            proteinGrams: 5,
            carbsGrams: 32,
            fatGrams: 7,
            servingDescription: "1 Katori (150g)"
        ),
        LocalFoodItem(
            name: "Samosa",
            keywords: ["samosa", "samosas", "aloo samosa", "punjabi samosa", "fried samosa"],
            servingGrams: 80,
            calories: 260,
            proteinGrams: 4,
            carbsGrams: 32,
            fatGrams: 13,
            servingDescription: "1 Piece (80g)"
        ),
        LocalFoodItem(
            name: "Curd",
            keywords: ["curd", "dahi", "plain curd", "yogurt", "indian yogurt", "raita", "plain dahi"],
            servingGrams: 150,
            calories: 90,
            proteinGrams: 5,
            carbsGrams: 6.5,
            fatGrams: 4.5,
            servingDescription: "1 Katori (150g)"
        ),
        LocalFoodItem(
            name: "Khichdi",
            keywords: ["khichdi", "dal khichdi", "moong dal khichdi", "khichri", "kichadi"],
            servingGrams: 200,
            calories: 220,
            proteinGrams: 7,
            carbsGrams: 38,
            fatGrams: 4.5,
            servingDescription: "1 Bowl (200g)"
        ),
        LocalFoodItem(
            name: "Aloo Gobi",
            keywords: ["aloo gobi", "alu gobi", "potato cauliflower", "gobi aloo", "cauliflower potato"],
            servingGrams: 150,
            calories: 140,
            proteinGrams: 3.5,
            carbsGrams: 18,
            fatGrams: 6.5,
            servingDescription: "1 Katori (150g)"
        ),
        LocalFoodItem(
            name: "Chicken Tikka",
            keywords: ["chicken tikka", "tandoori chicken", "chicken kebab", "tandoori tikka", "grilled chicken tikka"],
            servingGrams: 150,
            calories: 220,
            proteinGrams: 32,
            carbsGrams: 4,
            fatGrams: 8,
            servingDescription: "1 Plate (150g)"
        ),
        LocalFoodItem(
            name: "Naan",
            keywords: ["naan", "butter naan", "garlic naan", "plain naan", "tandoori naan"],
            servingGrams: 90,
            calories: 260,
            proteinGrams: 7.5,
            carbsGrams: 45,
            fatGrams: 5.5,
            servingDescription: "1 Piece (90g)"
        ),
        LocalFoodItem(
            name: "Paratha",
            keywords: ["paratha", "aloo paratha", "plain paratha", "stuffed paratha", "parotta"],
            servingGrams: 100,
            calories: 290,
            proteinGrams: 6,
            carbsGrams: 40,
            fatGrams: 12,
            servingDescription: "1 Piece (100g)"
        ),
        LocalFoodItem(
            name: "Gulab Jamun",
            keywords: ["gulab jamun", "gulab jamuns", "indian sweet", "jamun"],
            servingGrams: 50,
            calories: 175,
            proteinGrams: 2.5,
            carbsGrams: 26,
            fatGrams: 7,
            servingDescription: "1 Piece (50g)"
        ),
        LocalFoodItem(
            name: "Masala Chai",
            keywords: ["chai", "masala chai", "indian tea", "tea with milk", "milk tea"],
            servingGrams: 150,
            calories: 110,
            proteinGrams: 3,
            carbsGrams: 15,
            fatGrams: 4,
            servingDescription: "1 Cup (150ml)"
        ),
        LocalFoodItem(
            name: "Besan Chilla",
            keywords: ["chilla", "besan chilla", "cheela", "gram flour pancake", "puda"],
            servingGrams: 80,
            calories: 160,
            proteinGrams: 8,
            carbsGrams: 20,
            fatGrams: 5.5,
            servingDescription: "1 Piece (80g)"
        ),
        LocalFoodItem(
            name: "Egg Bhurji",
            keywords: ["egg bhurji", "anda bhurji", "scrambled eggs indian", "bhurji"],
            servingGrams: 120,
            calories: 180,
            proteinGrams: 13,
            carbsGrams: 3,
            fatGrams: 13,
            servingDescription: "1 Plate (120g)"
        )
    ]


    private static let mfpCatalog: [LocalFoodItem] = {
        let bundles = [Bundle.main, Bundle(for: FoodClassifierService.self)]
        for bundle in bundles {
            if let url = bundle.url(forResource: "MFPFoods", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder().decode([MFPFoodEntry].self, from: data) {
                return decoded.map { entry in
                    let desc = entry.defaultServingUnit != nil ? "\(Int(entry.defaultServingQuantity ?? 1)) \(entry.defaultServingUnit!)" : "\(Int(entry.servingGrams))g"
                    return LocalFoodItem(
                        name: entry.name,
                        keywords: [entry.name.lowercased()],
                        servingGrams: entry.servingGrams,
                        calories: entry.calories,
                        proteinGrams: entry.proteinGrams,
                        carbsGrams: entry.carbsGrams,
                        fatGrams: entry.fatGrams,
                        servingDescription: desc
                    )
                }
            }
        }
        return []
    }()

    private static var fullCatalog: [LocalFoodItem] {
        return catalog + mfpCatalog
    }

    public static func allItems() -> [LocalFoodItem] {
        return fullCatalog
    }

    public static func find(matching query: String) -> LocalFoodItem? {
        let cleaned = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !cleaned.isEmpty else { return nil }

        let searchSpace = fullCatalog

        // 1. Exact item name match
        if let exactName = searchSpace.first(where: { $0.name.lowercased() == cleaned }) {
            return exactName
        }

        // 2. Exact keyword match
        if let exactKeyword = searchSpace.first(where: { item in
            item.keywords.contains { $0.lowercased() == cleaned }
        }) {
            return exactKeyword
        }

        // 3. Name containment with word boundary matching
        if let nameContains = searchSpace.first(where: { item in
            let lowerName = item.name.lowercased()
            return matchesWordOrPhrase(cleaned, target: lowerName)
        }) {
            return nameContains
        }

        // 4. Keyword containment with word boundary matching - prioritize longest keyword match
        var bestKeywordMatch: (item: LocalFoodItem, length: Int)? = nil
        for item in searchSpace {
            for kw in item.keywords {
                let kwLower = kw.lowercased()
                if matchesWordOrPhrase(cleaned, target: kwLower) {
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

        for item in searchSpace {
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

    private static func matchesWordOrPhrase(_ query: String, target: String) -> Bool {
        if query == target { return true }

        // Fast checks before regex
        if query.count < target.count {
            // Check if query is a whole word in target
            if let regex = try? NSRegularExpression(pattern: "\\b" + NSRegularExpression.escapedPattern(for: query) + "\\b", options: [.caseInsensitive]) {
                let range = NSRange(location: 0, length: target.utf16.count)
                if regex.firstMatch(in: target, options: [], range: range) != nil {
                    return true
                }
            }
        } else {
            // Check if target is a whole word/phrase in query
            if let regex = try? NSRegularExpression(pattern: "\\b" + NSRegularExpression.escapedPattern(for: target) + "\\b", options: [.caseInsensitive]) {
                let range = NSRange(location: 0, length: query.utf16.count)
                if regex.firstMatch(in: query, options: [], range: range) != nil {
                    return true
                }
            }
        }
        return false
    }
}
