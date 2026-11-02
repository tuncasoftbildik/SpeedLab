import XCTest
import PDFKit
@testable import SpeedLab

final class ExportServiceTests: XCTestCase {
    func test_csvHeaderAndRow() {
        let r = SpeedTestResult(downloadSpeed: 85.5, uploadSpeed: 9.5, ping: 23, jitter: 4.1, ssid: "Ev, Salon", isp: "Turknet",
                                ipAddress: "1.2.3.4", connectionType: "wifi", carrier: "Turknet")
        let lines = ExportService.csv([r]).split(separator: "\n")
        XCTAssertEqual(lines[0], "date,connection,ssid,carrier,download_mbps,upload_mbps,ping_ms,jitter_ms,ip")
        XCTAssertTrue(lines[1].hasSuffix(",\"wifi\",\"Ev, Salon\",\"Turknet\",85.50,9.50,23.00,4.10,\"1.2.3.4\""), String(lines[1]))
        XCTAssertTrue(lines[1].hasPrefix("20"), "ISO 8601 tarih ile başlamalı")
    }

    func test_csvEmptyIsHeaderOnly() {
        XCTAssertEqual(ExportService.csv([]).split(separator: "\n").count, 1)
    }

    func test_pdfProducesDocument() {
        let data = ExportService.pdf(results: [], range: .day, chart: nil, title: "SpeedLab")
        XCTAssertTrue(data.starts(with: Array("%PDF".utf8)))
        XCTAssertEqual(PDFDocument(data: data)?.pageCount, 1)
    }

    func test_pdfPaginatesLongTables() {
        let many = (0..<80).map { i in
            SpeedTestResult(downloadSpeed: Double(i), uploadSpeed: 1, ping: 1, jitter: 1, date: Date(timeIntervalSinceNow: -Double(i) * 60))
        }
        let data = ExportService.pdf(results: many, range: .month, chart: nil, title: "SpeedLab")
        XCTAssertGreaterThan(PDFDocument(data: data)?.pageCount ?? 0, 1)
    }

    func test_fileName() {
        let now = ISO8601DateFormatter().date(from: "2026-11-02T12:00:00Z")!
        XCTAssertEqual(ExportService.fileName(kind: "csv", range: .week, now: now), "SpeedLab-2026-10-26-2026-11-02.csv")
    }

    /// Gözle inceleme için örnek PDF'i geçici klasöre yazar (yolu log'a basar).
    func test_pdfSampleRenderForReview() throws {
        var rows: [SpeedTestResult] = []
        for i in 0..<12 {
            let dl: Double = 40 + Double(i * 3)
            let ul: Double = 8 + Double(i)
            let ping: Double = 20 + Double(i)
            let wifi = i % 2 == 0
            let date = Date(timeIntervalSinceNow: -Double(i) * 18_000)
            rows.append(SpeedTestResult(downloadSpeed: dl, uploadSpeed: ul, ping: ping, jitter: 2.5,
                                        ssid: wifi ? "Ev" : "-", isp: "Turknet", ipAddress: "10.0.0.\(i)",
                                        connectionType: wifi ? "wifi" : "cellular", carrier: "Turknet", date: date))
        }
        let data = ExportService.pdf(results: rows, range: .week, chart: nil, title: "SpeedLab geçmişi")
        let url = URL(fileURLWithPath: "/tmp/speedlab-sample.pdf")
        try data.write(to: url)
        print("SAMPLE_PDF=\(url.path)")
        XCTAssertEqual(PDFDocument(data: data)?.pageCount, 1)
    }

    /// Güvenlik: hücre =,+,-,@,\t,\r ile başlarsa formül olarak yorumlanmasın (CSV enjeksiyonu).
    func test_csvNeutralizesFormulaInjection() {
        let r = SpeedTestResult(downloadSpeed: 1, uploadSpeed: 1, ping: 1, jitter: 1, ssid: "=HYPERLINK(\"http://x\")", isp: "+Evil", ipAddress: "1.1.1.1", carrier: "@cmd")
        let row = String(ExportService.csv([r]).split(separator: "\n")[1])
        XCTAssertTrue(row.contains("\"'=HYPERLINK(\"\"http://x\"\")\""), row)
        XCTAssertTrue(row.contains(",\"'@cmd\","), row)
        XCTAssertFalse(row.contains(",=HYPERLINK"), row)
    }

    func test_csvQuotesCarriageReturn() {
        let r = SpeedTestResult(downloadSpeed: 1, uploadSpeed: 1, ping: 1, jitter: 1, ssid: "Ev\rSalon")
        let row = String(ExportService.csv([r]).split(separator: "\n")[1])
        XCTAssertTrue(row.contains("\"Ev\rSalon\""), row)
    }

    /// Baştaki boşluktan sonra gelen tetikleyici de etkisizleştirilir; noktalı virgül içeren alan tırnaklı kalır.
    func test_csvTrimsLeadingWhitespaceBeforeTriggerCheck() {
        XCTAssertEqual(ExportService.escape("  =1+1"), "\"'  =1+1\"")
        XCTAssertEqual(ExportService.escape("a;b"), "\"a;b\"")
        XCTAssertEqual(ExportService.escape("\n=x"), "\"'\n=x\"")
        XCTAssertEqual(ExportService.escape("Ev"), "\"Ev\"")
    }

    /// Eski kayıtlardaki "-" yer tutucusu CSV'de boş hücre olur, "'-" değil.
    func test_csvLegacyDashBecomesEmpty() {
        let r = SpeedTestResult(downloadSpeed: 1, uploadSpeed: 1, ping: 1, jitter: 1, ssid: "-", isp: "Vodafone", ipAddress: "-")
        let row = String(ExportService.csv([r]).split(separator: "\n")[1])
        XCTAssertTrue(row.hasSuffix(",\"cellular\",\"\",\"Vodafone\",1.00,1.00,1.00,1.00,\"\""), row)
        XCTAssertFalse(row.contains("'-"), row)
    }
}
