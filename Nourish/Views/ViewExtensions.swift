import SwiftUI

extension View {
    @ViewBuilder
    func numericKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }
}
