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
