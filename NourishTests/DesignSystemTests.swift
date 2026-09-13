import XCTest
import SwiftUI
@testable import Nourish

final class DesignSystemTests: XCTestCase {

    func testThemeColors() {
        XCTAssertNotNil(ThemeColors.deepBackground)
        XCTAssertNotNil(ThemeColors.surfaceBackground)
        XCTAssertNotNil(ThemeColors.protein)
        XCTAssertNotNil(ThemeColors.carbs)
        XCTAssertNotNil(ThemeColors.fat)
        XCTAssertNotNil(ThemeColors.water)
    }

    func testFluidSprings() {
        let spring = FluidSprings.standard
        XCTAssertNotNil(spring)
    }

    func testLiquidProgressRingInitialization() {
        let ring = LiquidProgressRing(progress: 0.5, color: ThemeColors.protein)
        XCTAssertEqual(ring.progress, 0.5)
        XCTAssertEqual(ring.color, ThemeColors.protein)
    }

    func testMacroPillViewInitialization() {
        let pill = MacroPillView(title: "Protein", amount: "20g", color: ThemeColors.protein)
        XCTAssertEqual(pill.title, "Protein")
        XCTAssertEqual(pill.amount, "20g")
        XCTAssertEqual(pill.color, ThemeColors.protein)
    }

    func testFrostedCardInitialization() {
        let card = FrostedCard {
            Text("Hello")
        }
        XCTAssertNotNil(card)
    }
}
