import Foundation
import UIKit

/// Geçmişi CSV ve PDF olarak dışa aktarır (Pro).
enum ExportService {
    static let csvHeader = "date,connection,ssid,carrier,download_mbps,upload_mbps,ping_ms,jitter_ms,ip"

    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // MARK: - CSV

    static func csv(_ results: [SpeedTestResult]) -> String {
        var lines = [csvHeader]
        for r in results {
            let fields: [String] = [
                iso.string(from: r.date),
                r.effectiveConnectionType,
                r.ssid,
                r.carrier ?? r.isp,
                String(format: "%.2f", r.downloadSpeed),
                String(format: "%.2f", r.uploadSpeed),
                String(format: "%.2f", r.ping),
                String(format: "%.2f", r.jitter),
                r.ipAddress,
            ]
            lines.append(fields.map(escape).joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private static func escape(_ s: String) -> String {
        guard s.contains(",") || s.contains("\"") || s.contains("\n") else { return s }
        return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    // MARK: - Dosya adı

    static func fileName(kind: String, range: HistoryRange, now: Date) -> String {
        let start = now.addingTimeInterval(-range.seconds)
        return "SpeedLab-\(dayFormatter.string(from: start))-\(dayFormatter.string(from: now)).\(kind)"
    }

    // MARK: - PDF

    /// A4 tek/çok sayfa: başlık + aralık, özet (medyan), grafik görüntüsü, kayıt tablosu.
    static func pdf(results: [SpeedTestResult], range: HistoryRange, chart: UIImage?, title: String, now: Date = Date()) -> Data {
        let page = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat = 40
        let rowH: CGFloat = 16
        let bg = UIColor(hex: "0A0E27")
        let textColor = UIColor.white
        let dim = UIColor(hex: "94A3B8")
        let cyan = UIColor(hex: "06B6D4")

        let renderer = UIGraphicsPDFRenderer(bounds: page)
        return renderer.pdfData { ctx in
            var y: CGFloat = 0
            func newPage() {
                ctx.beginPage()
                bg.setFill(); UIBezierPath(rect: page).fill()
                y = margin
            }
            func draw(_ s: String, size: CGFloat, weight: UIFont.Weight = .regular, color: UIColor? = nil, x: CGFloat? = nil, width: CGFloat? = nil) {
                let x = x ?? margin
                let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color ?? textColor]
                (s as NSString).draw(in: CGRect(x: x, y: y, width: width ?? (page.width - x - margin), height: size + 6), withAttributes: attrs)
            }

            newPage()
            draw(title, size: 22, weight: .heavy)
            y += 30
            let start = now.addingTimeInterval(-range.seconds)
            draw("\(dayFormatter.string(from: start)) – \(dayFormatter.string(from: now)) · \(results.count) test", size: 11, color: dim)
            y += 24

            let med = { (xs: [Double]) -> String in SpeedContext.median(xs).map { String(format: "%.1f", $0) } ?? "—" }
            draw("↓ \(med(results.map(\.downloadSpeed))) Mbps    ↑ \(med(results.map(\.uploadSpeed))) Mbps    ping \(med(results.map(\.ping))) ms (medyan / median)",
                 size: 12, weight: .semibold, color: cyan)
            y += 26

            if let chart {
                let w = page.width - margin * 2
                let h = w * chart.size.height / chart.size.width
                chart.draw(in: CGRect(x: margin, y: y, width: w, height: h))
                y += h + 16
            }

            // Tablo başlığı
            let cols: [(String, CGFloat)] = [("Tarih / Date", 130), ("Bağlantı", 70), ("↓ Mbps", 70), ("↑ Mbps", 70), ("Ping", 55), ("Jitter", 55), ("Sağlayıcı", 65)]
            func header() {
                var x = margin
                for (name, w) in cols { draw(name, size: 9, weight: .semibold, color: dim, x: x, width: w); x += w }
                y += rowH
            }
            header()
            let df = DateFormatter(); df.dateFormat = "dd.MM.yyyy HH:mm"
            for r in results.sorted(by: { $0.date > $1.date }) {
                if y > page.height - margin - rowH { newPage(); header() }
                var x = margin
                let cells = [df.string(from: r.date), r.effectiveConnectionType,
                             String(format: "%.1f", r.downloadSpeed), String(format: "%.1f", r.uploadSpeed),
                             String(format: "%.0f", r.ping), String(format: "%.1f", r.jitter), r.carrier ?? r.isp]
                for (cell, (_, w)) in zip(cells, cols) { draw(cell, size: 9, x: x, width: w); x += w }
                y += rowH
            }
        }
    }
}
