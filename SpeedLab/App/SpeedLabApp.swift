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
    @State private var attCompleted = false

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
            .task {
                await requestATTAndConfigureAds()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    Task { await requestATTAndConfigureAds() }
                }
            }
        }
    }

    /// Ensures the ATT prompt is shown before AdMob is initialized.
    /// Apple requires the app to be foreground-active; we additionally
    /// delay slightly so the window has finished presenting (otherwise
    /// iOS can silently suppress the prompt on cold launches).
    private func requestATTAndConfigureAds() async {
        guard !attCompleted else { return }
        guard UIApplication.shared.applicationState == .active else { return }

        // Allow root window scene to fully present before showing the
        // system permission alert. Without this, the prompt is
        // occasionally dropped on cold-launch and the reviewer never
        // sees it (Guideline 5.1.2(i)).
        try? await Task.sleep(nanoseconds: 700_000_000)
        guard UIApplication.shared.applicationState == .active else { return }

        attCompleted = true
        _ = await TrackingManager.requestAuthorizationIfNeeded()
        AdManager.shared.configure()
        AdManager.shared.loadInterstitial()
        AdManager.shared.loadRewarded()
    }
}
