import Foundation

/// Kadranın logaritmik skalası: 0 → 0, 1000 Mbps → 1 (üstü doyar).
enum GaugeScale {
    static let maxMbps = 1000.0
    static let labels: [Double] = [0, 1, 5, 10, 50, 100, 500, 1000]

    private static let denominator = log10(maxMbps + 1)

    /// `log10(v+1)/log10(1001)`; negatif ve NaN → 0, ≥ 1000 → 1.
    static func fraction(_ mbps: Double) -> Double {
        guard mbps.isFinite, mbps > 0 else { return 0 }
        if mbps >= maxMbps { return 1 }
        return log10(mbps + 1) / denominator
    }

    static func label(_ value: Double) -> String {
        value >= 1000 ? "1G" : String(format: "%.0f", value)
    }
}
