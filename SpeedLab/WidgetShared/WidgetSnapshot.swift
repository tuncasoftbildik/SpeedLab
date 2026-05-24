import Foundation

struct WidgetSnapshot: Codable, Equatable {
    let download: Double
    let upload: Double
    let ping: Double
    let jitter: Double
    let isp: String
    let date: Date
}
