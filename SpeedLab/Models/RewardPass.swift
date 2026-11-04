import Foundation

/// Ödüllü reklamla açılan geçici Pro özellikleri (tam geçmiş, grafik aralığı, dışa aktarma).
/// Reklamsızlık bu geçişe dahil değildir; reklamlar yalnız gerçek Pro'da kalkar.
enum RewardPass {
    static let duration: TimeInterval = 24 * 3600
    static let storageKey = "reward_pro_until"

    static func isActive(until: Date?, now: Date = Date()) -> Bool {
        guard let until else { return false }
        return until > now
    }

    /// Yeni bitiş: süre bitmişse şimdiden, sürüyorsa kalan süreye 24 saat eklenir (en çok 48 saat ileri).
    static func extended(from until: Date?, now: Date = Date()) -> Date {
        let base = isActive(until: until, now: now) ? until! : now
        return min(base.addingTimeInterval(duration), now.addingTimeInterval(duration * 2))
    }

    static func remaining(until: Date?, now: Date = Date()) -> TimeInterval {
        guard let until, until > now else { return 0 }
        return until.timeIntervalSince(now)
    }

    static func load(_ defaults: UserDefaults = .standard) -> Date? {
        defaults.object(forKey: storageKey) as? Date
    }

    static func save(_ date: Date, _ defaults: UserDefaults = .standard) {
        defaults.set(date, forKey: storageKey)
    }
}
