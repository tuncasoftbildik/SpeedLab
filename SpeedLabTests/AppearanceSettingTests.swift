import XCTest
import SwiftUI
@testable import SpeedLab

final class AppearanceSettingTests: XCTestCase {
    func test_colorSchemeMapping() {
        XCTAssertNil(AppearanceSetting.system.colorScheme)
        XCTAssertEqual(AppearanceSetting.dark.colorScheme, .dark)
        XCTAssertEqual(AppearanceSetting.light.colorScheme, .light)
    }

    func test_defaultIsSystem() {
        XCTAssertEqual(AppearanceSetting(rawValue: "") ?? .system, .system)
        XCTAssertEqual(AppearanceSetting.storageKey, "appearance")
    }
}
