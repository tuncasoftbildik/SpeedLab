import Foundation

class HistoryService {
    private let key = "speed_test_history"
    private let maxFreeResults = 10

    func save(_ result: SpeedTestResult) {
        var history = loadAll()
        history.insert(result, at: 0)
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: key)
        }
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
