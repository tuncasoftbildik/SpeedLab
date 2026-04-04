import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private let pages: [(icon: String, colors: [Color], title: String, titleEn: String, desc: String, descEn: String)] = [
        ("gauge.with.dots.needle.67percent", [.npPurple, .npPrimary],
         "Hızını Ölç", "Test Your Speed",
         "İnternet hızını saniyeler içinde ölç.\nDownload, upload, ping ve jitter değerlerini gör.",
         "Measure your internet speed in seconds.\nSee download, upload, ping and jitter values."),

        ("wifi", [.npBlue, .npCyan],
         "WiFi Analizi", "WiFi Analysis",
         "Bağlı olduğun ağın detaylı bilgilerini gör.\nSinyal gücü, IP adresi ve servis sağlayıcı.",
         "See detailed info about your connected network.\nSignal strength, IP address and ISP."),

        ("chart.line.uptrend.xyaxis", [.npCyan, .npGreen],
         "Geçmişi Takip Et", "Track History",
         "Tüm test sonuçlarını kaydet ve karşılaştır.\nİnternet performansını zaman içinde izle.",
         "Save and compare all test results.\nMonitor internet performance over time."),
    ]

    @StateObject private var loc = LocalizationService.shared

    var body: some View {
        ZStack {
            Color.npBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Pages
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 28) {
                            Spacer()

                            // Icon circle
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(colors: pages[index].colors,
                                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 140, height: 140)
                                    .shadow(color: pages[index].colors[0].opacity(0.4), radius: 30)

                                Image(systemName: pages[index].icon)
                                    .font(.system(size: 56, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(.bottom, 8)

                            // Title
                            Text(loc.currentLanguage == "tr" ? pages[index].title : pages[index].titleEn)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            // Description
                            Text(loc.currentLanguage == "tr" ? pages[index].desc : pages[index].descEn)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.npTextSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 40)

                            Spacer()
                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom section
                VStack(spacing: 20) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? Color.npCyan : Color.npSurfaceLight)
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }

                    // Button
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(response: 0.4)) {
                                currentPage += 1
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                hasSeenOnboarding = true
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(currentPage < pages.count - 1
                                 ? (loc.currentLanguage == "tr" ? "Devam" : "Continue")
                                 : (loc.currentLanguage == "tr" ? "Başla" : "Get Started"))
                                .font(.system(size: 17, weight: .bold))

                            Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "bolt.fill")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: pages[currentPage].colors,
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: pages[currentPage].colors[0].opacity(0.4), radius: 12, y: 6)
                    }
                    .padding(.horizontal, 32)

                    // Skip
                    if currentPage < pages.count - 1 {
                        Button {
                            withAnimation { hasSeenOnboarding = true }
                        } label: {
                            Text(loc.currentLanguage == "tr" ? "Atla" : "Skip")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.npTextSecondary)
                        }
                    } else {
                        Color.clear.frame(height: 20)
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }
}
