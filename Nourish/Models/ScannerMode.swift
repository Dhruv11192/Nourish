import Foundation

enum ScannerMode: String, CaseIterable, Identifiable {
    case barcode = "Barcode"
    case ocrLabel = "Nutrition Label"
    case aiPlate = "AI Meal Photo"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .barcode: return "barcode.viewfinder"
        case .ocrLabel: return "text.viewfinder"
        case .aiPlate: return "camera.macro"
        }
    }
}
