import Foundation

enum HistoryRange: String, CaseIterable {
    case day, week, month

    var seconds: TimeInterval {
        switch self {
        case .day: return 86_400
        case .week: return 7 * 86_400
        case .month: return 30 * 86_400
        }
    }

    var localizationKey: String { "range_\(rawValue)" }
}

/// Geçmiş grafiği için filtre: tarih artan sırada döner.
/// Ücretsizde `range` yok sayılır ve en yeni `freeChartLimit` kayıt döner (Tunca'nın kararı: 3).
enum HistoryQuery {
    static let freeChartLimit = 3

    static func filter(_ results: [SpeedTestResult], kind: ConnectionKind?, carrier: String?,
                       range: HistoryRange, now: Date, isPro: Bool, freeChartLimit: Int = HistoryQuery.freeChartLimit) -> [SpeedTestResult] {
        var xs = results
        if let kind { xs = xs.filter { $0.effectiveKind == kind } }
        if let carrier, !carrier.isEmpty { xs = xs.filter { ($0.carrier ?? $0.isp) == carrier } }
        if isPro {
            let since = now.addingTimeInterval(-range.seconds)
            xs = xs.filter { $0.date >= since }
        } else {
            xs = Array(xs.sorted { $0.date > $1.date }.prefix(freeChartLimit))
        }
        return xs.sorted { $0.date < $1.date }
    }
}
