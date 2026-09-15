import XCTest
@testable import Kalai

final class MainTabViewTests: XCTestCase {
    func testViewsCompile() {
        // Here we ensure our Views compile.
        _ = MainTabView()
        _ = DiaryView()
        _ = DashboardView()
    }
}
