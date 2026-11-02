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

final class ConnectionHealthTests: XCTestCase {
    func test_scoreFromPingAndJitter() {
        XCTAssertEqual(ConnectionHealth.score(ping: 10, jitter: 1), 1, accuracy: 1e-9)
        XCTAssertEqual(ConnectionHealth.score(ping: 200, jitter: 50), 0, accuracy: 1e-9)
        let mid = ConnectionHealth.score(ping: 100, jitter: 10)
        XCTAssertGreaterThan(mid, 0.3); XCTAssertLessThan(mid, 0.7)
        XCTAssertGreaterThan(ConnectionHealth.score(ping: 40, jitter: 2), ConnectionHealth.score(ping: 40, jitter: 30))
    }

    func test_bandKeysReuseSignalBands() {
        XCTAssertEqual(SignalQuality.bandKey(ConnectionHealth.score(ping: 15, jitter: 2)), "signal_excellent")
        XCTAssertEqual(SignalQuality.bandKey(ConnectionHealth.score(ping: 180, jitter: 40)), "signal_weak")
    }
}
