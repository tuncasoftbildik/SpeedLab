import SwiftUI

struct ShareCardView: View {
    let result: SpeedTestResult
    let format: ShareCardFormat

    private let loc = LocalizationService.shared

    private var normalized: Double { min(result.downloadSpeed / 200.0, 1.0) }

    private var dateText: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = Locale(identifier: loc.language == .tr ? "tr_TR" : "en_US")
        return f.string(from: result.date)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Brand
            HStack(spacing: 14) {
                Image(systemName: "gauge.high")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(LinearGradient.npMain)
                Text("SpeedLab")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer(minLength: 24)

            ShareGaugeView(value: normalized, speed: result.downloadSpeed, diameter: 460)

            Spacer(minLength: 24)

            // Secondary metrics
            HStack(spacing: 64) {
                metric(symbol: "arrow.up", value: String(format: "%.1f", result.uploadSpeed), label: loc.t("upload"), color: .npPurple)
                metric(symbol: "dot.radiowaves.left.and.right", value: String(format: "%.0f", result.ping), label: loc.t("ping"), color: .npCyan)
                metric(symbol: "waveform.path", value: String(format: "%.0f", result.jitter), label: loc.t("jitter"), color: .npOrange)
            }

            Spacer(minLength: 20)

            // Footer: ISP · date
            Text(result.isp.isEmpty ? dateText : "\(result.isp) · \(dateText)")
                .font(.system(size: 30, weight: .medium))
                .foregroundColor(.npTextSecondary)

            Spacer(minLength: 36)

            // CTA + QR
            HStack(spacing: 28) {
                if let qr = QRCodeGenerator.generate(from: AppStoreLink.url) {
                    Image(uiImage: qr)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 150, height: 150)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(18)
                }
                Text(loc.t("share_cta"))
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(.npCyan)
            }
        }
        .padding(.vertical, format == .story ? 140 : 80)
        .padding(.horizontal, 80)
        .frame(width: format.pointSize.width, height: format.pointSize.height)
        .background(Color.npBackground)
    }

    private func metric(symbol: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(.npTextSecondary)
        }
    }
}

#Preview {
    ShareCardView(
        result: SpeedTestResult(downloadSpeed: 38.2, uploadSpeed: 12.4, ping: 14, jitter: 2, ssid: "Home", isp: "Turknet", ipAddress: "1.2.3.4"),
        format: .square
    )
}
