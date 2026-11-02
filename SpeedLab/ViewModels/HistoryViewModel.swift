import Foundation

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var results: [SpeedTestResult] = []

    private let historyService = HistoryService()

    func load(isPro: Bool = false) {
        results = isPro ? historyService.loadAll() : historyService.loadFree()
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
