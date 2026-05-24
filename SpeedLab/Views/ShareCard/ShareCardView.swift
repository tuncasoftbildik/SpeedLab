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
        VStack(spacing: format == .story ? 44 : 26) {
            // Brand
            HStack(spacing: 8) {
                Image(systemName: "gauge.high")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(LinearGradient.npMain)
                Text("SpeedLab")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }

            ShareGaugeView(value: normalized, speed: result.downloadSpeed)

            // Secondary metrics
            HStack(spacing: 28) {
                metric(symbol: "arrow.up", value: String(format: "%.1f", result.uploadSpeed), label: loc.t("upload"), color: .npPurple)
                metric(symbol: "dot.radiowaves.left.and.right", value: String(format: "%.0f", result.ping), label: loc.t("ping"), color: .npCyan)
                metric(symbol: "waveform.path", value: String(format: "%.0f", result.jitter), label: loc.t("jitter"), color: .npOrange)
            }

            // Footer: ISP · date
            if !result.isp.isEmpty {
                Text("\(result.isp) · \(dateText)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.npTextSecondary)
            } else {
                Text(dateText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.npTextSecondary)
            }

            // CTA + QR
            HStack(spacing: 14) {
                if let qr = QRCodeGenerator.generate(from: AppStoreLink.url) {
                    Image(uiImage: qr)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 76, height: 76)
                        .padding(6)
                        .background(Color.white)
                        .cornerRadius(10)
                }
                Text(loc.t("share_cta"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.npCyan)
            }
            .padding(.top, format == .story ? 8 : 0)
        }
        .padding(format == .story ? 48 : 36)
        .frame(width: format.pointSize.width, height: format.pointSize.height)
        .background(Color.npBackground)
    }

    private func metric(symbol: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
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
