import XCTest
@testable import Kalai

final class MacroRingTests: XCTestCase {
    func testRingCalculations() {
        let ring = MacroRingView(total: 1000, consumed: 500)
        XCTAssertEqual(ring.percentage, 0.5)
    }

    func testRingCalculationsCappedAtOne() {
        let ring = MacroRingView(total: 1000, consumed: 1500)
        XCTAssertEqual(ring.percentage, 1.0)
    }

    func testRingCalculationsZeroTotal() {
        let ring = MacroRingView(total: 0, consumed: 0)
        XCTAssertEqual(ring.percentage, 0.0)
    }
}
