import SwiftUI

struct MainTabView: View {
    @StateObject private var localization = LocalizationService.shared
    @EnvironmentObject var storeVM: StoreViewModel

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                SpeedTestView()
                    .tabItem {
                        Image(systemName: "gauge.with.dots.needle.33percent")
                        Text(localization.t("tab_speed"))
                    }

                WiFiAnalyzerView()
                    .tabItem {
                        Image(systemName: "wifi")
                        Text(localization.t("tab_wifi"))
                    }

                HistoryView()
                    .tabItem {
                        Image(systemName: "clock.arrow.circlepath")
                        Text(localization.t("tab_history"))
                    }

                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text(localization.t("tab_settings"))
                    }
            }
            .tint(.npCyan)
            .id(localization.currentLanguage)

            // Banner reklam (Pro kullanıcılara gösterme)
            if !storeVM.isPro {
                BannerAdView()
                    .frame(height: 50)
                    .background(Color.npBackground)
            }
        }
    }
}
