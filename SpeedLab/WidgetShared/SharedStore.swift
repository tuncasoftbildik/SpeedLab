import Foundation

enum AppGroup {
    static let id = "group.com.vialab.speedlab"
}

struct SharedStore {
    private let defaults: UserDefaults
    private let snapshotKey = "widget_snapshot"
    private let proKey = "widget_is_pro"
    private let recentKey = "widget_recent_downloads"

    init(defaults: UserDefaults? = UserDefaults(suiteName: AppGroup.id)) {
        self.defaults = defaults ?? .standard
    }

    func save(_ snapshot: WidgetSnapshot) {
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: snapshotKey)
        }
    }

    func loadSnapshot() -> WidgetSnapshot? {
        guard let data = defaults.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func setPro(_ isPro: Bool) { defaults.set(isPro, forKey: proKey) }
    func isPro() -> Bool { defaults.bool(forKey: proKey) }

    func saveRecent(_ downloads: [Double]) { defaults.set(downloads, forKey: recentKey) }
    func recentDownloads() -> [Double] { (defaults.array(forKey: recentKey) as? [Double]) ?? [] }
}
