import XCTest
@testable import SpeedLab

final class HistoryQueryTests: XCTestCase {
    private func r(_ dl: Double, daysAgo: Double, ssid: String = "Ev", isp: String = "Turknet") -> SpeedTestResult {
        SpeedTestResult(downloadSpeed: dl, uploadSpeed: 1, ping: 1, jitter: 1, ssid: ssid, isp: isp, ipAddress: "",
                        date: Date(timeIntervalSinceNow: -daysAgo * 86400))
    }

    func test_freeReturnsNewestThreeIgnoringRange() {
        let xs = [r(1, daysAgo: 0), r(2, daysAgo: 1), r(3, daysAgo: 2), r(4, daysAgo: 40)]
        let out = HistoryQuery.filter(xs, kind: nil, carrier: nil, range: .month, now: Date(), isPro: false)
        XCTAssertEqual(out.map(\.downloadSpeed), [3, 2, 1])
    }

    func test_proRangeAndKindFilter() {
        let xs = [r(1, daysAgo: 0), r(2, daysAgo: 3, ssid: "-"), r(3, daysAgo: 10), r(4, daysAgo: 40)]
        XCTAssertEqual(HistoryQuery.filter(xs, kind: nil, carrier: nil, range: .week, now: Date(), isPro: true).count, 2)
        XCTAssertEqual(HistoryQuery.filter(xs, kind: .cellular, carrier: nil, range: .month, now: Date(), isPro: true).map(\.downloadSpeed), [2])
    }

    func test_emptyAndSingle() {
        XCTAssertTrue(HistoryQuery.filter([], kind: nil, carrier: nil, range: .day, now: Date(), isPro: true).isEmpty)
        XCTAssertEqual(HistoryQuery.filter([r(9, daysAgo: 0)], kind: nil, carrier: "Turknet", range: .day, now: Date(), isPro: true).count, 1)
        XCTAssertEqual(HistoryQuery.filter([r(9, daysAgo: 0)], kind: nil, carrier: "Vodafone", range: .day, now: Date(), isPro: true).count, 0)
    }

    func test_rangeSeconds() {
        XCTAssertEqual(HistoryRange.day.seconds, 86400)
        XCTAssertEqual(HistoryRange.week.seconds, 7 * 86400)
        XCTAssertEqual(HistoryRange.month.seconds, 30 * 86400)
    }
}
