import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum HapticFeedback {
    enum Style {
        case light
        case medium
        case rigid
    }

    static func trigger(_ style: Style) {
        #if canImport(UIKit)
        let impactStyle: UIImpactFeedbackGenerator.FeedbackStyle
        switch style {
        case .light: impactStyle = .light
        case .medium: impactStyle = .medium
        case .rigid: impactStyle = .rigid
        }
        let generator = UIImpactFeedbackGenerator(style: impactStyle)
        generator.impactOccurred()
        #endif
        // No haptics on macOS
    }
}
