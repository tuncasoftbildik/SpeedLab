import XCTest
@testable import SpeedLab

final class GaugeScaleTests: XCTestCase {
    func test_edges() {
        XCTAssertEqual(GaugeScale.fraction(0), 0, accuracy: 1e-9)
        XCTAssertEqual(GaugeScale.fraction(1000), 1, accuracy: 1e-9)
        XCTAssertEqual(GaugeScale.fraction(5000), 1)
        XCTAssertEqual(GaugeScale.fraction(-3), 0)
        XCTAssertEqual(GaugeScale.fraction(.nan), 0)
    }

    func test_monotonicAndMid() {
        XCTAssertEqual(GaugeScale.fraction(100), log10(101) / log10(1001), accuracy: 1e-9)
        XCTAssertLessThan(GaugeScale.fraction(10), GaugeScale.fraction(50))
    }

    func test_labels() {
        XCTAssertEqual(GaugeScale.label(1000), "1G")
        XCTAssertEqual(GaugeScale.label(50), "50")
        XCTAssertEqual(GaugeScale.labels, [0, 1, 5, 10, 50, 100, 500, 1000])
    }
}
