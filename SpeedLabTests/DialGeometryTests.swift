import XCTest
import SwiftUI
@testable import SpeedLab

final class DialGeometryTests: XCTestCase {
    func test_startAndEndAngles() {
        let g = DialGeometry(center: CGPoint(x: 100, y: 100), radius: 100)
        XCTAssertEqual(g.angle(fraction: 0).degrees, -135, accuracy: 1e-9)
        XCTAssertEqual(g.angle(fraction: 1).degrees, 135, accuracy: 1e-9)
    }

    func test_topIsFractionHalf() {
        let g = DialGeometry(center: CGPoint(x: 100, y: 100), radius: 100)
        let p = g.point(fraction: 0.5, radius: 100)
        XCTAssertEqual(p.x, 100, accuracy: 1e-6)
        XCTAssertEqual(p.y, 0, accuracy: 1e-6)
    }

    func test_startIsBottomLeft() {
        let g = DialGeometry(center: CGPoint(x: 100, y: 100), radius: 100)
        let p = g.point(fraction: 0, radius: 100)
        XCTAssertLessThan(p.x, 100)
        XCTAssertGreaterThan(p.y, 100)
    }
}
