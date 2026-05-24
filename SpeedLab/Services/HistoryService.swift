import Foundation
import WidgetKit

class HistoryService {
    private let key = "speed_test_history"
    private let maxFreeResults = 10

    func save(_ result: SpeedTestResult) {
        var history = loadAll()
        history.insert(result, at: 0)
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: key)
        }
        syncWidget(history)
    }

    func syncWidget(_ history: [SpeedTestResult]) {
        let store = SharedStore()
        if let latest = history.first {
            store.save(WidgetSnapshot(
                download: latest.downloadSpeed,
                upload: latest.uploadSpeed,
                ping: latest.ping,
                jitter: latest.jitter,
                isp: latest.isp,
                date: latest.date
            ))
        }
        store.saveRecent(Array(history.prefix(3).map { $0.downloadSpeed }))
        WidgetCenter.shared.reloadAllTimelines()
    }

    func loadAll() -> [SpeedTestResult] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let results = try? JSONDecoder().decode([SpeedTestResult].self, from: data) else {
            return []
        }
        return results
    }

    func loadFree() -> [SpeedTestResult] {
        return Array(loadAll().prefix(maxFreeResults))
    }

    func deleteAll() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    func delete(_ id: UUID) {
        var history = loadAll()
        history.removeAll { $0.id == id }
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
