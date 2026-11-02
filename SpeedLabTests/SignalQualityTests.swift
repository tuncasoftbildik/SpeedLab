import XCTest
@testable import SpeedLab

final class SignalQualityTests: XCTestCase {
    func test_bands() {
        XCTAssertEqual(SignalQuality.bandKey(nil), "signal_unavailable")
        XCTAssertEqual(SignalQuality.bandKey(0), "signal_unavailable")
        XCTAssertEqual(SignalQuality.bandKey(0.2), "signal_weak")
        XCTAssertEqual(SignalQuality.bandKey(0.5), "signal_fair")
        XCTAssertEqual(SignalQuality.bandKey(0.7), "signal_good")
        XCTAssertEqual(SignalQuality.bandKey(0.95), "signal_excellent")
    }

    func test_percent() {
        XCTAssertEqual(SignalQuality.percent(0.734), 73)
        XCTAssertNil(SignalQuality.percent(0))
        XCTAssertNil(SignalQuality.percent(nil))
        XCTAssertEqual(SignalQuality.percent(1.4), 100)
    }
}
