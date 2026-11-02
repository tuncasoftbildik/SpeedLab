import Foundation

/// Sonuç kartlarındaki bağlam satırı: kullanım bandı ve ortalamaya göre fark.
enum SpeedContext {
    enum Metric { case download, upload, ping }

    /// Sözlük anahtarı döner (`loc.t(...)` ile metne çevrilir).
    static func bandKey(_ metric: Metric, value: Double) -> String {
        switch metric {
        case .download:
            switch value {
            case ..<5: return "band_dl_music"
            case ..<25: return "band_dl_hd"
            case ..<50: return "band_dl_4k"
            case ..<100: return "band_dl_office"
            default: return "band_dl_fiber"
            }
        case .upload:
            switch value {
            case ..<3: return "band_ul_weak"
            case ..<10: return "band_ul_call"
            default: return "band_ul_stream"
            }
        case .ping:
            switch value {
            case ..<30: return "band_ping_gaming"
            case ..<80: return "band_ping_good"
            default: return "band_ping_laggy"
            }
        }
    }

    /// Son 10 değerin medyanına göre yüzde fark; 2'den az geçmiş → nil; |fark| < %5 → 0.
    static func deltaPercent(current: Double, history: [Double]) -> Int? {
        let recent = Array(history.suffix(10))
        guard recent.count >= 2, let med = median(recent), med > 0 else { return nil }
        let pct = (current - med) / med * 100
        guard abs(pct) >= 5 else { return 0 }
        return Int(pct.rounded())
    }

    static func median(_ xs: [Double]) -> Double? {
        guard !xs.isEmpty else { return nil }
        let s = xs.sorted()
        let mid = s.count / 2
        return s.count % 2 == 0 ? (s[mid - 1] + s[mid]) / 2 : s[mid]
    }
}
