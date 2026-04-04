import SwiftUI
import GoogleMobileAds

@main
struct SpeedLabApp: App {
    @StateObject private var speedTestVM = SpeedTestViewModel()
    @StateObject private var wifiVM = WiFiViewModel()
    @StateObject private var historyVM = HistoryViewModel()
    @StateObject private var storeVM = StoreViewModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    init() {
        AdManager.shared.configure()
        AdManager.shared.loadInterstitial()
        AdManager.shared.loadRewarded()
    }

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                MainTabView()
                    .environmentObject(speedTestVM)
                    .environmentObject(wifiVM)
                    .environmentObject(historyVM)
                    .environmentObject(storeVM)
                    .preferredColorScheme(.dark)
            } else {
                OnboardingView()
                    .preferredColorScheme(.dark)
            }
        }
    }
}
