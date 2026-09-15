import SwiftUI

enum KalaiTheme {
    struct Colors {
        let background = Color(red: 24/255, green: 26/255, blue: 23/255) // Dark Charcoal (#1C1E1B)
        let surface = Color(red: 63/255, green: 75/255, blue: 59/255)   // Muted Olive (#3F4B3B)
        let accent = Color(red: 194/255, green: 168/255, blue: 149/255) // Ochre (#C2A895)
        let text = Color(red: 240/255, green: 234/255, blue: 214/255)   // Soft Cream (#F0EAD6)
    }

    static let colors = Colors()

    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.7)
}

extension View {
    func kalaiBackground() -> some View {
        self.background(KalaiTheme.colors.background.ignoresSafeArea())
    }
}
