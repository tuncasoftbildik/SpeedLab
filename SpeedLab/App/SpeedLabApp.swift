import SwiftUI
import GoogleMobileAds

@main
struct SpeedLabApp: App {
    @StateObject private var speedTestVM = SpeedTestViewModel()
    @StateObject private var wifiVM = WiFiViewModel()
    @StateObject private var historyVM = HistoryViewModel()
    @StateObject private var storeVM = StoreViewModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var adsInitialized = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    MainTabView()
                        .environmentObject(speedTestVM)
                        .environmentObject(wifiVM)
                        .environmentObject(historyVM)
                        .environmentObject(storeVM)
                } else {
                    OnboardingView()
                }
            }
            .preferredColorScheme(.dark)
            .task(id: scenePhase) {
                // Request ATT once the scene is active (Apple requires
                // foreground state for the prompt), then initialize AdMob.
                // Running here instead of App.init avoids the pre-14.5
                // init-time ordering problem.
                guard scenePhase == .active, !adsInitialized else { return }
                adsInitialized = true
                _ = await TrackingManager.requestAuthorizationIfNeeded()
                AdManager.shared.configure()
                AdManager.shared.loadInterstitial()
                AdManager.shared.loadRewarded()
            }
        }
    }
}
