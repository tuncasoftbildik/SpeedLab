import Foundation

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

    init(downloadSpeed: Double, uploadSpeed: Double, ping: Double, jitter: Double, ssid: String = "", isp: String = "", ipAddress: String = "") {
        self.id = UUID()
        self.downloadSpeed = downloadSpeed
        self.uploadSpeed = uploadSpeed
        self.ping = ping
        self.jitter = jitter
        self.ssid = ssid
        self.isp = isp
        self.ipAddress = ipAddress
        self.date = Date()
    }
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
