import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable {
    case tr = "tr"
    case en = "en"

    var displayName: String {
        switch self {
        case .tr: return "Turkce"
        case .en: return "English"
        }
    }

    var flag: String {
        switch self {
        case .tr: return "🇹🇷"
        case .en: return "🇺🇸"
        }
    }
}

class LocalizationService: ObservableObject {
    static let shared = LocalizationService()

    @AppStorage("app_language", store: UserDefaults(suiteName: AppGroup.id)) var currentLanguage: String = "tr" {
        didSet { objectWillChange.send() }
    }

    init() {
        // One-time migration: copy a previously-saved language from standard
        // defaults into the shared App Group suite (where @AppStorage now reads).
        let group = UserDefaults(suiteName: AppGroup.id)
        if group?.string(forKey: "app_language") == nil,
           let legacy = UserDefaults.standard.string(forKey: "app_language") {
            group?.set(legacy, forKey: "app_language")
        }
    }

    var language: AppLanguage {
        get { AppLanguage(rawValue: currentLanguage) ?? .tr }
        set { currentLanguage = newValue.rawValue }
    }

    // MARK: - Strings
    func t(_ key: String) -> String {
        return strings[key]?[currentLanguage] ?? key
    }

    private let strings: [String: [String: String]] = [
        // Tab Bar
        "tab_speed": ["tr": "Hız Testi", "en": "Speed Test"],
        "tab_wifi": ["tr": "WiFi Analiz", "en": "WiFi Analyzer"],
        "tab_history": ["tr": "Geçmiş", "en": "History"],
        "tab_settings": ["tr": "Ayarlar", "en": "Settings"],

        // Speed Test
        "start_test": ["tr": "Başlat", "en": "Start"],
        "testing_ping": ["tr": "Ping ölçülüyor...", "en": "Measuring ping..."],
        "testing_download": ["tr": "İndirme testi...", "en": "Download test..."],
        "testing_upload": ["tr": "Yükleme testi...", "en": "Upload test..."],
        "completed": ["tr": "Tamamlandı", "en": "Completed"],
        "download": ["tr": "İndirme", "en": "Download"],
        "upload": ["tr": "Yükleme", "en": "Upload"],
        "ping": ["tr": "Ping", "en": "Ping"],
        "jitter": ["tr": "Jitter", "en": "Jitter"],

        // Widget
        "widget_pro_title": ["tr": "SpeedLab Pro", "en": "SpeedLab Pro"],
        "widget_pro_sub": ["tr": "Hız sonuçlarını ana ekranında gör", "en": "See your speeds on the Home Screen"],
        "widget_empty": ["tr": "İlk testini çalıştır", "en": "Run your first test"],
        "widget_recent": ["tr": "Son testler", "en": "Recent"],

        // Share card
        "share_cta": ["tr": "Sen de ölç →", "en": "Test yours →"],
        "share_caption": ["tr": "SpeedLab ile ölçtüm", "en": "Measured with SpeedLab"],
        "share_format_title": ["tr": "Kart formatı", "en": "Card format"],
        "share_format_square": ["tr": "Kare", "en": "Square"],
        "share_format_story": ["tr": "Story", "en": "Story"],
        "quality_excellent": ["tr": "Mükemmel", "en": "Excellent"],
        "quality_good": ["tr": "İyi", "en": "Good"],
        "quality_slow": ["tr": "Yavaş", "en": "Slow"],
        "tap_to_start": ["tr": "Test başlatmak için dokunun", "en": "Tap to start test"],
        "network": ["tr": "Ağ", "en": "Network"],
        "isp": ["tr": "Servis Sağlayıcı", "en": "ISP"],
        "ip_address": ["tr": "IP Adresi", "en": "IP Address"],
        "share_result": ["tr": "Sonucu Paylaş", "en": "Share Result"],

        // WiFi
        "wifi_info": ["tr": "WiFi Bilgileri", "en": "WiFi Information"],
        "signal_strength": ["tr": "Sinyal Gücü", "en": "Signal Strength"],
        "network_name": ["tr": "Ağ Adı", "en": "Network Name"],
        "connection_type": ["tr": "Bağlantı Türü", "en": "Connection Type"],
        "local_ip": ["tr": "Yerel IP", "en": "Local IP"],
        "public_ip": ["tr": "Genel IP", "en": "Public IP"],
        "refresh": ["tr": "Yenile", "en": "Refresh"],
        "excellent": ["tr": "Mükemmel", "en": "Excellent"],
        "good": ["tr": "İyi", "en": "Good"],
        "fair": ["tr": "Orta", "en": "Fair"],
        "weak": ["tr": "Zayıf", "en": "Weak"],

        // History
        "test_history": ["tr": "Test Geçmişi", "en": "Test History"],
        "no_results": ["tr": "Henüz test yapılmadı", "en": "No tests yet"],
        "average": ["tr": "Ortalama", "en": "Average"],
        "delete_all": ["tr": "Tümünü Sil", "en": "Delete All"],
        "delete_confirm": ["tr": "Tüm geçmiş silinsin mi?", "en": "Delete all history?"],
        "cancel": ["tr": "İptal", "en": "Cancel"],
        "delete": ["tr": "Sil", "en": "Delete"],
        "pro_limit": ["tr": "Ücretsiz sürümde son 10 test görünür", "en": "Free version shows last 10 tests"],

        // Settings
        "settings": ["tr": "Ayarlar", "en": "Settings"],
        "language": ["tr": "Dil", "en": "Language"],
        "pro_version": ["tr": "Pro Sürüm", "en": "Pro Version"],
        "upgrade_pro": ["tr": "Pro'ya Yükselt", "en": "Upgrade to Pro"],
        "restore_purchases": ["tr": "Satın Alımları Geri Yükle", "en": "Restore Purchases"],
        "redeem_code": ["tr": "Promosyon Kodu Kullan", "en": "Redeem Code"],
        "pro_features": ["tr": "Pro Özellikleri", "en": "Pro Features"],
        "feature_no_ads": ["tr": "Reklamsız deneyim", "en": "Ad-free experience"],
        "feature_unlimited_history": ["tr": "Sınırsız test geçmişi", "en": "Unlimited test history"],
        "feature_wifi_map": ["tr": "WiFi sinyal haritası", "en": "WiFi signal map"],
        "feature_export": ["tr": "CSV/PDF dışa aktarma", "en": "CSV/PDF export"],
        "feature_widget": ["tr": "Ana ekran widget", "en": "Home screen widget"],
        "monthly": ["tr": "Aylık", "en": "Monthly"],
        "yearly": ["tr": "Yıllık", "en": "Yearly"],
        "version": ["tr": "Sürüm", "en": "Version"],
        "rate_app": ["tr": "Uygulamayı Değerlendir", "en": "Rate App"],
        "privacy_policy": ["tr": "Gizlilik Politikası", "en": "Privacy Policy"],
        "terms": ["tr": "Kullanım Koşulları", "en": "Terms of Use"],
        "about": ["tr": "Hakkında", "en": "About"],
        "made_by": ["tr": "ViaLab tarafından geliştirildi", "en": "Developed by ViaLab"],

        // Rewarded Ad
        "watch_ad_extra_test": ["tr": "Reklam İzle, Ekstra Test Kazan", "en": "Watch Ad, Earn Extra Test"],
        "watch_ad_detail": ["tr": "Reklam izleyerek detaylı raporu gör", "en": "Watch ad to see detailed report"],
        "reward_earned": ["tr": "Ekstra test hakkı kazandın!", "en": "You earned an extra test!"],
    ]
}
