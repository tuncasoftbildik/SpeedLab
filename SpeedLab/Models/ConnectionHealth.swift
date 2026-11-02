import Foundation

/// iOS WiFi sinyal gücünü vermediğinde (HotspotHelper izni yok) kadran son hız testinden türetilen
/// "bağlantı sağlığı"nı gösterir: ping ve jitter'dan 0–1 puan. Bantlar SignalQuality ile ortak.
enum ConnectionHealth {
    /// ping ≤ 20 ms → 1, ≥ 200 ms → 0 (lineer); jitter ≤ 2 ms → 1, ≥ 50 ms → 0. Ağırlık: ping 0.7, jitter 0.3.
    static func score(ping: Double, jitter: Double) -> Double {
        let p = 1 - clamp((ping - 20) / 180)
        let j = 1 - clamp((jitter - 2) / 48)
        return clamp(0.7 * p + 0.3 * j)
    }

    private static func clamp(_ x: Double) -> Double { min(max(x, 0), 1) }
}
