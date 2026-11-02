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
        // Görünüm
        "appearance": ["tr": "Görünüm", "en": "Appearance"],
        "appearance_system": ["tr": "Sistem", "en": "System"],
        "appearance_dark": ["tr": "Koyu", "en": "Dark"],
        "appearance_light": ["tr": "Açık", "en": "Light"],

        // Bağlam bantları (SpeedContext)
        "band_dl_music": ["tr": "müzik ve web için yeterli", "en": "fine for music and web"],
        "band_dl_hd": ["tr": "HD video için yeterli", "en": "enough for HD video"],
        "band_dl_4k": ["tr": "4K yayın için yeterli", "en": "enough for 4K streaming"],
        "band_dl_office": ["tr": "ev ofisi için ferah", "en": "roomy for home office"],
        "band_dl_fiber": ["tr": "fiber sınıfı", "en": "fiber class"],
        "band_ul_weak": ["tr": "görüşmede zorlanır", "en": "struggles on calls"],
        "band_ul_call": ["tr": "video görüşme için yeterli", "en": "enough for video calls"],
        "band_ul_stream": ["tr": "yayın ve yükleme için iyi", "en": "good for streaming and uploads"],
        "band_ping_gaming": ["tr": "oyun için ideal", "en": "ideal for gaming"],
        "band_ping_good": ["tr": "iyi", "en": "good"],
        "band_ping_laggy": ["tr": "gecikmeli", "en": "laggy"],
        "context_avg": ["tr": "ortalamada", "en": "on average"],
        "context_up": ["tr": "↑ %{p} ortalamaya göre", "en": "↑ {p}% vs. average"],
        "context_down": ["tr": "↓ %{p} ortalamaya göre", "en": "↓ {p}% vs. average"],

        // Ana ekran 1.2
        "packet_loss": ["tr": "Kayıp", "en": "Loss"],
        "live_flow": ["tr": "Canlı akış", "en": "Live flow"],
        "last_30s": ["tr": "Son test", "en": "Last test"],
        "queued": ["tr": "sırada", "en": "queued"],
        "measuring_download": ["tr": "İndirme ölçülüyor", "en": "Measuring download"],
        "measuring_upload": ["tr": "Yükleme ölçülüyor", "en": "Measuring upload"],
        "kind_wifi": ["tr": "WiFi", "en": "WiFi"],
        "kind_cellular": ["tr": "Hücresel", "en": "Cellular"],
        "kind_wired": ["tr": "Kablolu", "en": "Wired"],

        // Geçmiş 1.2
        "range_day": ["tr": "Gün", "en": "Day"],
        "range_week": ["tr": "Hafta", "en": "Week"],
        "range_month": ["tr": "Ay", "en": "Month"],
        "filter_all": ["tr": "Tümü", "en": "All"],
        "filter_wifi": ["tr": "WiFi", "en": "WiFi"],
        "filter_cellular": ["tr": "Hücresel", "en": "Cellular"],
        "free_chart_note": ["tr": "Son 3 test · Pro ile tüm geçmiş", "en": "Last 3 tests · full history with Pro"],
        "export": ["tr": "Dışa aktar", "en": "Export"],

        // Dışa aktarma
        "export_csv": ["tr": "CSV (tüm kayıtlar)", "en": "CSV (all records)"],
        "export_pdf": ["tr": "PDF (seçili aralık)", "en": "PDF (selected range)"],
        "export_title": ["tr": "SpeedLab geçmişi", "en": "SpeedLab history"],

        // WiFi 1.2
        "signal_quality": ["tr": "Sinyal kalitesi", "en": "Signal quality"],
        "signal_weak": ["tr": "Zayıf", "en": "Weak"],
        "signal_fair": ["tr": "Orta", "en": "Fair"],
        "signal_good": ["tr": "İyi", "en": "Good"],
        "signal_excellent": ["tr": "Mükemmel", "en": "Excellent"],
        "signal_unavailable": ["tr": "Henüz ölçüm yok", "en": "No measurement yet"],
        "health_from_last_test": ["tr": "Bağlantı sağlığı · son hız testine göre (ping ve jitter)", "en": "Connection health · from your last speed test (ping and jitter)"],
        "health_no_test": ["tr": "iOS sinyal gücünü paylaşmıyor · bir hız testi yapın", "en": "iOS doesn't share signal strength · run a speed test"],
        "signal_history": ["tr": "Sinyal geçmişi · 60 sn", "en": "Signal history · 60 s"],
        "ios_not_shared": ["tr": "iOS paylaşmıyor", "en": "not shared by iOS"],
        "ios_limitation_note": ["tr": "iOS, uygulamalara sinyal gücü (dBm), bant ve kanal bilgisini vermez; bu değerler yalnız Ayarlar > Wi-Fi'da görünür.", "en": "iOS doesn't expose signal strength (dBm), band or channel to apps; those are only visible in Settings > Wi-Fi."],
        "band": ["tr": "Bant", "en": "Band"],
        "channel": ["tr": "Kanal", "en": "Channel"],
        "bssid": ["tr": "BSSID", "en": "BSSID"],
        "radio_tech": ["tr": "Radyo", "en": "Radio"],
        "unknown": ["tr": "Bilinmiyor", "en": "Unknown"],

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
        "feature_export": ["tr": "CSV / PDF dışa aktarma", "en": "CSV / PDF export"],
        "benefit_no_ads_sub": ["tr": "Banner ve geçiş reklamları kalkar", "en": "No banner or interstitial ads"],
        "benefit_history_sub": ["tr": "Tüm kayıtlar, hafta ve ay grafiği", "en": "All records, week and month charts"],
        "benefit_export_sub": ["tr": "Tablo ve rapor olarak paylaş", "en": "Share as table or report"],
        "feature_widget": ["tr": "Ana ekran widget", "en": "Home screen widget"],
        "monthly": ["tr": "Aylık", "en": "Monthly"],
        "yearly": ["tr": "Yıllık", "en": "Yearly"],
        "version": ["tr": "Sürüm", "en": "Version"],
        "rate_app": ["tr": "Uygulamayı Değerlendir", "en": "Rate App"],
        "privacy_policy": ["tr": "Gizlilik Politikası", "en": "Privacy Policy"],
        "terms": ["tr": "Kullanım Koşulları", "en": "Terms of Use"],
        "about": ["tr": "Hakkında", "en": "About"],
        "made_by": ["tr": "ViaLab tarafından geliştirildi", "en": "Developed by ViaLab"],

    ]
}
