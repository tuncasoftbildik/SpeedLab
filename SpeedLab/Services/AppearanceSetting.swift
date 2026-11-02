import SwiftUI

/// Görünüm tercihi: Sistem (varsayılan) / Koyu / Açık. `@AppStorage(AppearanceSetting.storageKey)` ile saklanır.
enum AppearanceSetting: String, CaseIterable {
    case system
    case dark
    case light

    static let storageKey = "appearance"

    /// `preferredColorScheme` için; `.system` nil döner (sistemi takip eder).
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }

    var localizationKey: String {
        switch self {
        case .system: return "appearance_system"
        case .dark: return "appearance_dark"
        case .light: return "appearance_light"
        }
    }
}
