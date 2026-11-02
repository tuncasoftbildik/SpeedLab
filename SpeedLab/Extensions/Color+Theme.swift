import SwiftUI
import UIKit

// MARK: - Marka renkleri (SABİT KOYU)
// Widget ve paylaşım kartı yalnız bunları kullanır: marka görseli her yerde aynı görünür.
extension Color {
    static let npBrandBackground = Color(hex: "0A0E27")
    static let npBrandSurface = Color(hex: "141832")
    static let npBrandSurfaceLight = Color(hex: "1E2448")
    static let npBrandTextPrimary = Color.white
    static let npBrandTextSecondary = Color(hex: "94A3B8")
    static let npBrandBorder = Color(hex: "1E293B")
}

// MARK: - Vurgu renkleri (her iki temada aynı)
extension Color {
    static let npPrimary = Color(hex: "6366F1")     // İndigo
    static let npBlue = Color(hex: "3B82F6")
    static let npCyan = Color(hex: "06B6D4")
    static let npGreen = Color(hex: "10B981")
    static let npOrange = Color(hex: "F59E0B")
    static let npRed = Color(hex: "EF4444")
    static let npPurple = Color(hex: "A855F7")

    // Gradient
    static let npGradientStart = Color(hex: "6366F1")
    static let npGradientMid = Color(hex: "3B82F6")
    static let npGradientEnd = Color(hex: "06B6D4")
}

// MARK: - Semantik renkler (uygulama görünümleri; koyu/açık temaya göre çözülür)
extension Color {
    static let npBackground = Color.adaptive(dark: "0A0E27", light: "F4F6FB")
    static let npSurface = Color.adaptive(dark: "141832", light: "FFFFFF", lightAlpha: 0.70)
    static let npSurfaceLight = Color.adaptive(dark: "1E2448", light: "E9EDF7")
    static let npTextPrimary = Color.adaptive(dark: "FFFFFF", light: "0B1020")
    static let npTextSecondary = Color.adaptive(dark: "94A3B8", light: "5B6478")
    static let npBorder = Color.adaptive(dark: "1E293B", light: "D6DBEA")

    /// Trait'e göre koyu/açık hex çözen renk.
    static func adaptive(dark: String, light: String, lightAlpha: CGFloat = 1) -> Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hex: dark)
                : UIColor(hex: light).withAlphaComponent(lightAlpha)
        })
    }

    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

extension LinearGradient {
    static let npMain = LinearGradient(
        colors: [.npGradientStart, .npGradientMid, .npGradientEnd],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let npButton = LinearGradient(
        colors: [.npPrimary, .npBlue],
        startPoint: .leading, endPoint: .trailing
    )
}
