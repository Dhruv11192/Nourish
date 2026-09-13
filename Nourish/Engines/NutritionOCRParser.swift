import Foundation
import Vision
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
typealias UIImage = NSImage

extension NSImage {
    var cgImage: CGImage? {
        var rect = NSRect(origin: .zero, size: self.size)
        return self.cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }
}
#endif

enum OCRParserError: LocalizedError {
    case invalidImage
    case textRecognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Unable to process the image for text recognition."
        case .textRecognitionFailed(let reason):
            return "Text recognition failed: \(reason)"
        }
    }
}

enum NutritionOCRParser {

    // MARK: - Main Parsing Entry Points

    static func parseNutritionFacts(from lines: [String]) -> ParsedNutritionData {
        let cleanedLines = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !cleanedLines.isEmpty else {
            return ParsedNutritionData()
        }

        // Generate combined candidate lines for multi-line tokens
        var candidateLines = cleanedLines
        if cleanedLines.count > 1 {
            for i in 0..<(cleanedLines.count - 1) {
                candidateLines.append("\(cleanedLines[i]) \(cleanedLines[i + 1])")
            }
        }
        let fullText = cleanedLines.joined(separator: "\n")

        let calories = extractCalories(from: candidateLines, fullText: fullText)
        let fat = extractFat(from: candidateLines, fullText: fullText)
        let carbs = extractCarbohydrates(from: candidateLines, fullText: fullText)
        let protein = extractProtein(from: candidateLines, fullText: fullText)
        let (servingSize, servingWeightGrams) = extractServingInfo(from: candidateLines)

        return ParsedNutritionData(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            servingSize: servingSize,
            servingWeightGrams: servingWeightGrams
        )
    }

    static func parseNutritionFacts(from text: String) -> ParsedNutritionData {
        let lines = text.components(separatedBy: .newlines)
        return parseNutritionFacts(from: lines)
    }

    static func parseVisionObservations(_ observations: [VNRecognizedTextObservation]) -> ParsedNutritionData {
        let lines = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }
        return parseNutritionFacts(from: lines)
    }

    // MARK: - Vision OCR Runners

    static func recognizeText(from cgImage: CGImage) throws -> [String] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results else {
            return []
        }

        return observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }
    }

    static func parseNutritionFacts(from cgImage: CGImage) throws -> ParsedNutritionData {
        let lines = try recognizeText(from: cgImage)
        return parseNutritionFacts(from: lines)
    }

    static func recognizeText(from image: UIImage) throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw OCRParserError.invalidImage
        }
        return try recognizeText(from: cgImage)
    }

    static func parseNutritionFacts(from image: UIImage) throws -> ParsedNutritionData {
        guard let cgImage = image.cgImage else {
            throw OCRParserError.invalidImage
        }
        return try parseNutritionFacts(from: cgImage)
    }

    // MARK: - Nutrient Extraction Details

    private static func extractCalories(from candidates: [String], fullText: String) -> Double? {
        // 1. Check for explicit kcal in European/international formats (e.g. "850 kJ / 200 kcal" or "200 kcal")
        let kcalPattern = #"(\d+(?:[.,]\d+)?)\s*kcal\b"#
        for candidate in candidates {
            if let match = firstMatch(pattern: kcalPattern, in: candidate), match.count > 1,
               let val = parseDouble(match[1]) {
                return val
            }
        }

        // 2. Check for standard US Calories (e.g. "Calories 230", "Calories: 230", "Amount Per Serving Calories 230")
        let caloriesPattern = #"\b(?:Calories?|Calor[ie1l]es?)\b(?!\s+from\s+fat)[^\d\n]*(\d+(?:[.,]\d+)?)"#
        for candidate in candidates {
            if let match = firstMatch(pattern: caloriesPattern, in: candidate), match.count > 1,
               let val = parseDouble(match[1]) {
                return val
            }
        }

        // 3. Check for Energy with plain numbers (avoid matching if it's kJ)
        let energyPattern = #"\b(?:Energy|Energie)\b[^\d\n]*(\d+(?:[.,]\d+)?)(?!\d|\s*k[Jj])"#
        for candidate in candidates {
            if let match = firstMatch(pattern: energyPattern, in: candidate), match.count > 1,
               let val = parseDouble(match[1]) {
                return val
            }
        }

        // 4. Check for kJ-only energy (convert kJ to kcal: kJ / 4.184)
        let kJPatttern = #"\b(\d+(?:[.,]\d+)?)\s*k[Jj]\b"#
        for candidate in candidates {
            if let match = firstMatch(pattern: kJPatttern, in: candidate), match.count > 1,
               let kJVal = parseDouble(match[1]) {
                return (kJVal / 4.184).rounded()
            }
        }

        return nil
    }

    private static func extractFat(from candidates: [String], fullText: String) -> Double? {
        // 1. Explicit Total Fat
        let explicitKeywords = [
            #"(?:Total|Tot\.?)\s+Fat"#,
            #"Grasas\s+Totales"#,
            #"Lipides\s+Totaux"#
        ]
        for candidate in candidates {
            for kw in explicitKeywords {
                if let val = extractValueAfterKeyword(pattern: kw, in: candidate) {
                    return val
                }
            }
        }

        // 2. Standalone Fat (avoid Saturated, Trans, Poly, Mono)
        let negativeKeywords = ["saturated", "saturates", "trans", "polyunsaturated", "monounsaturated"]
        let standaloneKeywords = [
            #"\bFat\b"#,
            #"\bLipides?\b"#,
            #"\bGrasas?\b"#
        ]

        for candidate in candidates {
            let lower = candidate.lowercased()
            let hasNegative = negativeKeywords.contains { lower.contains($0) }
            if !hasNegative {
                for kw in standaloneKeywords {
                    if let val = extractValueAfterKeyword(pattern: kw, in: candidate) {
                        return val
                    }
                }
            }
        }

        return nil
    }

    private static func extractCarbohydrates(from candidates: [String], fullText: String) -> Double? {
        // 1. Explicit Total Carbohydrate
        let explicitKeywords = [
            #"(?:Total|Tot\.?)\s+(?:Carbohydrates?|Carbs?|Carb\.?)"#,
            #"Glucides\s+Totaux"#,
            #"Carbohidratos\s+Totales"#
        ]
        for candidate in candidates {
            for kw in explicitKeywords {
                if let val = extractValueAfterKeyword(pattern: kw, in: candidate) {
                    return val
                }
            }
        }

        // 2. General Carbohydrates (avoid sugars, fiber)
        let negativeKeywords = ["sugar", "sugars", "sucre", "fiber", "fibre", "azucar", "azúcares"]
        let generalKeywords = [
            #"\bCarbohydrates?\b"#,
            #"\bCarbs?\b"#,
            #"\bCarb\.?\b"#,
            #"\bGlucides?\b"#,
            #"\bCarbohidratos?\b"#
        ]

        for candidate in candidates {
            let lower = candidate.lowercased()
            let hasNegative = negativeKeywords.contains { lower.contains($0) }
            if !hasNegative {
                for kw in generalKeywords {
                    if let val = extractValueAfterKeyword(pattern: kw, in: candidate) {
                        return val
                    }
                }
            }
        }

        return nil
    }

    private static func extractProtein(from candidates: [String], fullText: String) -> Double? {
        let keywords = [
            #"\bProtein\b"#,
            #"\bProteins\b"#,
            #"\bProteines?\b"#,
            #"\bProteinas?\b"#
        ]
        for candidate in candidates {
            for kw in keywords {
                if let val = extractValueAfterKeyword(pattern: kw, in: candidate) {
                    return val
                }
            }
        }
        return nil
    }

    private static func extractServingInfo(from candidates: [String]) -> (servingSize: String?, servingWeightGrams: Double?) {
        var detectedServingSize: String? = nil
        var detectedWeight: Double? = nil

        // Look for weight in parentheses, e.g. "(228g)" or "(55 g)"
        let parentheticalWeightPattern = #"\(\s*(\d+(?:[.,]\d+)?)\s*g\s*\)"#
        for candidate in candidates {
            if let match = firstMatch(pattern: parentheticalWeightPattern, in: candidate), match.count > 1,
               let val = parseDouble(match[1]) {
                detectedWeight = val
                break
            }
        }

        // Look for Serving Size line
        let servingSizePattern = #"\b(?:Serving\s*Size|Portion|Per\s+serving|Serving\s*size)\b[:\s]*(.+)"#
        for candidate in candidates {
            if let match = firstMatch(pattern: servingSizePattern, in: candidate), match.count > 1 {
                let rawText = match[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: ":- "))
                if !rawText.isEmpty {
                    detectedServingSize = rawText

                    if detectedWeight == nil {
                        // Check if serving size string has grams (e.g. "55g" or "100g")
                        let gramPattern = #"(\d+(?:[.,]\d+)?)\s*g\b"#
                        if let gMatch = firstMatch(pattern: gramPattern, in: rawText), gMatch.count > 1,
                           let val = parseDouble(gMatch[1]) {
                            detectedWeight = val
                        }
                    }
                    break
                }
            }
        }

        // Look for "Per 100g" format
        if detectedWeight == nil {
            let per100gPattern = #"\bPer\s+(\d+(?:[.,]\d+)?)\s*g\b"#
            for candidate in candidates {
                if let match = firstMatch(pattern: per100gPattern, in: candidate), match.count > 1,
                   let val = parseDouble(match[1]) {
                    detectedWeight = val
                    if detectedServingSize == nil {
                        detectedServingSize = "\(Int(val))g"
                    }
                    break
                }
            }
        }

        return (detectedServingSize, detectedWeight)
    }

    // MARK: - Helper regex and value extractors

    private static func extractValueAfterKeyword(pattern: String, in text: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        let matchEndIndex = match.range.location + match.range.length
        guard let postRange = Range(NSRange(location: matchEndIndex, length: text.utf16.count - matchEndIndex), in: text) else {
            return nil
        }
        let postKeywordText = String(text[postRange])

        // Step 1: Look for gram value (e.g. "8g", "8.5 g", "8 grams") - highest precedence to strip percentages
        let gramPattern = #"(\d+(?:[.,]\d+)?)\s*(?:g\b|grams?\b|g\.)"#
        if let match = firstMatch(pattern: gramPattern, in: postKeywordText), match.count > 1,
           let val = parseDouble(match[1]) {
            return val
        }

        // Step 2: Look for number not followed by % (percentage stripping)
        let numberNotPercentPattern = #"(?<!\d)(\d+(?:[.,]\d+)?)(?!\d|\s*%)"#
        if let match = firstMatch(pattern: numberNotPercentPattern, in: postKeywordText), match.count > 1,
           let val = parseDouble(match[1]) {
            return val
        }

        // Step 3: Any number
        let anyNumberPattern = #"(\d+(?:[.,]\d+)?)"#
        if let match = firstMatch(pattern: anyNumberPattern, in: postKeywordText), match.count > 1,
           let val = parseDouble(match[1]) {
            return val
        }

        return nil
    }

    private static func firstMatch(pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }
        var groups: [String] = []
        for i in 0..<match.numberOfRanges {
            let groupRange = match.range(at: i)
            if groupRange.location != NSNotFound, let r = Range(groupRange, in: text) {
                groups.append(String(text[r]))
            } else {
                groups.append("")
            }
        }
        return groups
    }

    private static func parseDouble(_ string: String) -> Double? {
        let sanitized = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Double(sanitized)
    }
}
