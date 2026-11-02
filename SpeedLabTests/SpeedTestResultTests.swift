import XCTest
@testable import SpeedLab

final class SpeedTestResultTests: XCTestCase {
    func test_decodesLegacyRecordWithoutNewFields() throws {
        let legacy = """
        [{"id":"5E4C0F3A-1B2C-4D5E-8F90-ABCDEF123456","downloadSpeed":37.5,"uploadSpeed":9.5,"ping":147,"jitter":37.4,"ssid":"-","isp":"Vodafone","ipAddress":"-","date":734000000}]
        """.data(using: .utf8)!
        let r = try JSONDecoder().decode([SpeedTestResult].self, from: legacy)
        XCTAssertEqual(r.count, 1)
        XCTAssertNil(r[0].downloadSamples)
        XCTAssertEqual(r[0].effectiveConnectionType, "cellular")
    }

    func test_wifiInferredFromSSID() {
        let r = SpeedTestResult(downloadSpeed: 1, uploadSpeed: 1, ping: 1, jitter: 1, ssid: "Ev", isp: "", ipAddress: "")
        XCTAssertEqual(r.effectiveConnectionType, "wifi")
    }

    func test_roundTripWithSamples() throws {
        let r = SpeedTestResult(downloadSpeed: 85.5, uploadSpeed: 20, ping: 23, jitter: 4.1, ssid: "Ev", isp: "Turknet", ipAddress: "1.2.3.4",
                                downloadSamples: [10, 50, 85.5], uploadSamples: [5, 20], connectionType: "wifi", carrier: "Turknet")
        let d = try JSONDecoder().decode(SpeedTestResult.self, from: JSONEncoder().encode(r))
        XCTAssertEqual(d.downloadSamples, [10, 50, 85.5])
        XCTAssertEqual(d.carrier, "Turknet")
    }

    func test_customDateParameter() {
        let past = Date(timeIntervalSinceNow: -86400)
        let r = SpeedTestResult(downloadSpeed: 1, uploadSpeed: 1, ping: 1, jitter: 1, date: past)
        XCTAssertEqual(r.date, past)
    }
}
