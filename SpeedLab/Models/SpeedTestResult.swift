import Foundation

/// Bağlantı türü; `SpeedTestResult.connectionType` ham değeri ve geçmiş filtresi bunu kullanır.
enum ConnectionKind: String, CaseIterable, Codable {
    case wifi
    case cellular
    case wired
}

struct SpeedTestResult: Identifiable, Codable {
    let id: UUID
    let downloadSpeed: Double // Mbps
    let uploadSpeed: Double   // Mbps
    let ping: Double          // ms
    let jitter: Double        // ms
    let ssid: String
    let isp: String
    let ipAddress: String
    let date: Date

    // 1.2.0 — opsiyonel; 1.1.2 kayıtlarında yok, decode'da nil kalır.
    let downloadSamples: [Double]?
    let uploadSamples: [Double]?
    let connectionType: String?   // ConnectionKind.rawValue
    let carrier: String?          // ipinfo org (ISP)

    init(downloadSpeed: Double, uploadSpeed: Double, ping: Double, jitter: Double,
         ssid: String = "", isp: String = "", ipAddress: String = "",
         downloadSamples: [Double]? = nil, uploadSamples: [Double]? = nil,
         connectionType: String? = nil, carrier: String? = nil,
         date: Date = Date()) {
        self.id = UUID()
        self.downloadSpeed = downloadSpeed
        self.uploadSpeed = uploadSpeed
        self.ping = ping
        self.jitter = jitter
        self.ssid = ssid
        self.isp = isp
        self.ipAddress = ipAddress
        self.downloadSamples = downloadSamples
        self.uploadSamples = uploadSamples
        self.connectionType = connectionType
        self.carrier = carrier
        self.date = date
    }

    /// Kayıtlı tür; eski kayıtlarda SSID boş/"-" ise hücresel, aksi WiFi sayılır.
    var effectiveConnectionType: String {
        if let connectionType, !connectionType.isEmpty { return connectionType }
        return (ssid.isEmpty || ssid == "-") ? ConnectionKind.cellular.rawValue : ConnectionKind.wifi.rawValue
    }

    var effectiveKind: ConnectionKind { ConnectionKind(rawValue: effectiveConnectionType) ?? .wifi }
}

enum SpeedTestPhase: String {
    case idle = "Başlat"
    case preparingPing = "Ping hazırlanıyor..."
    case testingPing = "Ping ölçülüyor..."
    case preparingDownload = "İndirme hazırlanıyor..."
    case testingDownload = "İndirme testi..."
    case preparingUpload = "Yükleme hazırlanıyor..."
    case testingUpload = "Yükleme testi..."
    case completed = "Tamamlandı"
}

struct NetworkInfo {
    var ssid: String = "-"
    var bssid: String = "-"
    var ipAddress: String = "-"
    var isp: String = "-"
    var signalStrength: Int = 0 // -100 to 0 dBm
    var frequency: String = "-"
    var linkSpeed: String = "-"
}
