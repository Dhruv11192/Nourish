import XCTest
import SwiftUI
@testable import Kalai

final class KalaiThemeTests: XCTestCase {
    func testBackgroundIsDark() {
        XCTAssertEqual(KalaiTheme.colors.background, Color(red: 24/255, green: 26/255, blue: 23/255))
    }

    func testTextIsSoftCream() {
        XCTAssertEqual(KalaiTheme.colors.text, Color(red: 240/255, green: 234/255, blue: 214/255))
    }

    func testSurfaceAndAccentColors() {
        XCTAssertEqual(KalaiTheme.colors.surface, Color(red: 63/255, green: 75/255, blue: 59/255))
        XCTAssertEqual(KalaiTheme.colors.accent, Color(red: 194/255, green: 168/255, blue: 149/255))
    }
}
