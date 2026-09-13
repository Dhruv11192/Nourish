import Foundation

public enum MealType: String, Codable, CaseIterable, Identifiable, Sendable {
    case breakfast
    case lunch
    case dinner
    case snack

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .breakfast:
            return "Breakfast"
        case .lunch:
            return "Lunch"
        case .dinner:
            return "Dinner"
        case .snack:
            return "Snacks"
        }
    }

    public var iconName: String {
        switch self {
        case .breakfast:
            return "sun.horizon.fill"
        case .lunch:
            return "sun.max.fill"
        case .dinner:
            return "moon.stars.fill"
        case .snack:
            return "cup.and.saucer.fill"
        }
    }
}
