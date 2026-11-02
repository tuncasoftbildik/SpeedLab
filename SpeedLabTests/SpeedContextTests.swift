import XCTest
@testable import SpeedLab

final class SpeedContextTests: XCTestCase {
    func test_downloadBands() {
        XCTAssertEqual(SpeedContext.bandKey(.download, value: 4.9), "band_dl_music")
        XCTAssertEqual(SpeedContext.bandKey(.download, value: 12), "band_dl_hd")
        XCTAssertEqual(SpeedContext.bandKey(.download, value: 37.5), "band_dl_4k")
        XCTAssertEqual(SpeedContext.bandKey(.download, value: 75), "band_dl_office")
        XCTAssertEqual(SpeedContext.bandKey(.download, value: 100), "band_dl_fiber")
    }

    func test_uploadAndPingBands() {
        XCTAssertEqual(SpeedContext.bandKey(.upload, value: 2), "band_ul_weak")
        XCTAssertEqual(SpeedContext.bandKey(.upload, value: 9.5), "band_ul_call")
        XCTAssertEqual(SpeedContext.bandKey(.upload, value: 20), "band_ul_stream")
        XCTAssertEqual(SpeedContext.bandKey(.ping, value: 23), "band_ping_gaming")
        XCTAssertEqual(SpeedContext.bandKey(.ping, value: 50), "band_ping_good")
        XCTAssertEqual(SpeedContext.bandKey(.ping, value: 147), "band_ping_laggy")
    }

    func test_delta() {
        XCTAssertNil(SpeedContext.deltaPercent(current: 50, history: [40]))
        XCTAssertEqual(SpeedContext.deltaPercent(current: 56, history: [50, 50, 50]), 12)
        XCTAssertEqual(SpeedContext.deltaPercent(current: 51, history: [50, 50, 50]), 0)
        XCTAssertEqual(SpeedContext.deltaPercent(current: 40, history: [50, 50]), -20)
        XCTAssertEqual(SpeedContext.median([3, 1, 2]), 2)
        XCTAssertEqual(SpeedContext.median([4, 1, 2, 3]), 2.5)
        XCTAssertNil(SpeedContext.median([]))
    }

    func test_deltaUsesLastTenOnly() {
        // 12 değer: ilk ikisi uçuk; son 10'un medyanı 50
        let history = [500.0, 500.0] + Array(repeating: 50.0, count: 10)
        XCTAssertEqual(SpeedContext.deltaPercent(current: 55, history: history), 10)
    }
}
