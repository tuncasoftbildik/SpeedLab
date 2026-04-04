import SwiftUI

extension Color {
    static let npBackground = Color(hex: "0A0E27")
    static let npSurface = Color(hex: "141832")
    static let npSurfaceLight = Color(hex: "1E2448")
    static let npPrimary = Color(hex: "6366F1")     // İndigo
    static let npBlue = Color(hex: "3B82F6")
    static let npCyan = Color(hex: "06B6D4")
    static let npGreen = Color(hex: "10B981")
    static let npOrange = Color(hex: "F59E0B")
    static let npRed = Color(hex: "EF4444")
    static let npPurple = Color(hex: "A855F7")
    static let npTextPrimary = Color.white
    static let npTextSecondary = Color(hex: "94A3B8")
    static let npBorder = Color(hex: "1E293B")

    // Gradient
    static let npGradientStart = Color(hex: "6366F1")
    static let npGradientMid = Color(hex: "3B82F6")
    static let npGradientEnd = Color(hex: "06B6D4")

    init(hex: String) {
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
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
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
