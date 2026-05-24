import XCTest
@testable import SpeedLab

final class SmokeTests: XCTestCase {
    func test_appModuleLoads() {
        XCTAssertEqual(AppLanguage.tr.rawValue, "tr")
    }
}
