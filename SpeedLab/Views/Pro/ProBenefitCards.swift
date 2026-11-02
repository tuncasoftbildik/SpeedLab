import SwiftUI

/// Pro sayfası fayda önizlemeleri: reklamsız, tam geçmiş + grafik ufku, CSV/PDF dışa aktarma.
/// Görseller gerçek bileşenlerden (HistoryChartView) örnek veriyle çizilir.
struct ProBenefitCards: View {
    @StateObject private var loc = LocalizationService.shared

    private static let sample: [SpeedTestResult] = {
        let speeds: [Double] = [42, 58, 51, 66, 73, 61, 80]
        return speeds.enumerated().map { i, dl in
            SpeedTestResult(downloadSpeed: dl, uploadSpeed: dl * 0.22, ping: 18 + Double(i * 3), jitter: 2,
                            date: Date(timeIntervalSinceNow: -Double(6 - i) * 86_400))
        }
    }()

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                card(title: loc.t("feature_no_ads"), subtitle: loc.t("benefit_no_ads_sub"), tint: .npCyan) {
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 8).fill(Color.npBrandSurfaceLight).frame(height: 28)
                            .overlay(Text("AD").font(.system(size: 10, weight: .bold)).foregroundColor(.npBrandTextSecondary))
                            .overlay(Rectangle().fill(Color.npRed).frame(height: 2).rotationEffect(.degrees(-8)))
                        RoundedRectangle(cornerRadius: 8).fill(Color.npCyan.opacity(0.25)).frame(height: 28)
                            .overlay(Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.npCyan))
                    }
                }
                card(title: loc.t("feature_unlimited_history"), subtitle: loc.t("benefit_history_sub"), tint: .npPurple) {
                    HistoryChartView(results: Self.sample, height: 70, compact: true)
                        .allowsHitTesting(false)
                }
                card(title: loc.t("feature_export"), subtitle: loc.t("benefit_export_sub"), tint: .npBlue) {
                    HStack(spacing: 10) {
                        fileBadge("CSV", .npGreen)
                        fileBadge("PDF", .npRed)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func card<Content: View>(title: String, subtitle: String, tint: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            content()
                .frame(height: 70)
                .frame(maxWidth: .infinity)
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.npBrandTextPrimary)
                .lineLimit(1)
            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.npBrandTextSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(width: 170, alignment: .leading)
        .background(Color.npBrandSurface)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(tint.opacity(0.35), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func fileBadge(_ ext: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: "doc.fill").font(.system(size: 26)).foregroundColor(color.opacity(0.9))
            Text(ext).font(.system(size: 10, weight: .bold)).foregroundColor(.npBrandTextPrimary)
        }
        .frame(width: 56, height: 60)
        .background(Color.npBrandSurfaceLight)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
