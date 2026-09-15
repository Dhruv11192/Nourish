import XCTest
import SwiftUI
@testable import Kalai

final class BarcodeScannerTests: XCTestCase {
    func testBarcodeScannerViewInstantiation() {
        let scanner = BarcodeScannerView(onScan: { _ in })
        XCTAssertNotNil(scanner)
    }
}
