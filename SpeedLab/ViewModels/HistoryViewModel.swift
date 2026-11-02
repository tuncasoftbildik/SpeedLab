import Foundation

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var results: [SpeedTestResult] = []
    @Published var range: HistoryRange = .day
    @Published var kind: ConnectionKind? = nil
    @Published var carrier: String? = nil

    private let historyService = HistoryService()

    func load(isPro: Bool = false) {
        results = isPro ? historyService.loadAll() : historyService.loadFree()
    }

    /// Grafik verisi: ücretsizde son 3 test, Pro'da seçili aralık ve filtreler.
    func chartResults(isPro: Bool, now: Date = Date()) -> [SpeedTestResult] {
        HistoryQuery.filter(historyService.loadAll(), kind: kind, carrier: carrier, range: range, now: now, isPro: isPro)
    }

    /// Liste: tür/sağlayıcı çipleri uygulanmış (ücretsiz 10 sınırı `results` üzerinden korunur).
    var filteredResults: [SpeedTestResult] { HistoryQuery.narrow(results, kind: kind, carrier: carrier) }

    /// Dışa aktarma için tüm kayıtlar (Pro).
    func allResults() -> [SpeedTestResult] { historyService.loadAll() }

    /// Benzersiz sağlayıcılar, alfabetik.
    var carriers: [String] {
        Array(Set(results.map { $0.carrier ?? $0.isp }.filter { !$0.isEmpty && $0 != "-" })).sorted()
    }

    /// Pro değilse Hafta/Ay seçilemez (false döner, görünüm Pro sayfasını açar).
    @discardableResult
    func requestRange(_ r: HistoryRange, isPro: Bool) -> Bool {
        if !isPro && r != .day { return false }
        range = r
        return true
    }

    func delete(_ id: UUID) {
        historyService.delete(id)
        results.removeAll { $0.id == id }
    }

    func deleteAll() {
        historyService.deleteAll()
        results = []
    }

    /// Bağlam farkı için geçmiş değerler (en yeni önce), isteğe bağlı bağlantı türü filtresi ve bir kaydın dışlanması.
    func recentValues(_ metric: SpeedContext.Metric, kind: ConnectionKind?, excluding id: UUID?, limit: Int = 10) -> [Double] {
        var all = historyService.loadAll()
        if let id { all.removeAll { $0.id == id } }
        if let kind {
            let same = all.filter { $0.effectiveKind == kind }
            if same.count >= 2 { all = same }
        }
        let picked = Array(all.prefix(limit))
        switch metric {
        case .download: return picked.map(\.downloadSpeed)
        case .upload: return picked.map(\.uploadSpeed)
        case .ping: return picked.map(\.ping)
        }
    }

    /// Son test (yoksa nil).
    func lastResult() -> SpeedTestResult? { historyService.loadAll().first }

    /// Boştaki grafik için son testin örnekleri (yoksa boş).
    func lastSamples(download: Bool) -> [Double] {
        guard let last = historyService.loadAll().first else { return [] }
        return (download ? last.downloadSamples : last.uploadSamples) ?? []
    }

    var averageDownload: Double {
        guard !results.isEmpty else { return 0 }
        return results.map(\.downloadSpeed).reduce(0, +) / Double(results.count)
    }

    var averageUpload: Double {
        guard !results.isEmpty else { return 0 }
        return results.map(\.uploadSpeed).reduce(0, +) / Double(results.count)
    }

    var averagePing: Double {
        guard !results.isEmpty else { return 0 }
        return results.map(\.ping).reduce(0, +) / Double(results.count)
    }
}
