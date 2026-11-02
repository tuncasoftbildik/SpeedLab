import Foundation

/// iOS'un verdiği 0–1 normalize sinyal değerini dürüstçe yorumlar (dBm yok).
enum SignalQuality {
    /// nil veya ≤ 0 → "signal_unavailable"; <0.3 zayıf, <0.55 orta, <0.8 iyi, aksi mükemmel.
    static func bandKey(_ q: Double?) -> String {
        guard let q, q > 0 else { return "signal_unavailable" }
        switch q {
        case ..<0.3: return "signal_weak"
        case ..<0.55: return "signal_fair"
        case ..<0.8: return "signal_good"
        default: return "signal_excellent"
        }
    }

    static func percent(_ q: Double?) -> Int? {
        guard let q, q > 0 else { return nil }
        return Int((min(q, 1) * 100).rounded())
    }
}
