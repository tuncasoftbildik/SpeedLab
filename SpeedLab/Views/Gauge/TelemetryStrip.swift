import SwiftUI

/// Kadranın üstündeki üç cam çip: Ping, Jitter, Kayıp. nil → "—".
struct TelemetryStrip: View {
    let ping: Double?
    let jitter: Double?
    let loss: Double?
    @StateObject private var loc = LocalizationService.shared

    var body: some View {
        HStack(spacing: 10) {
            chip(loc.t("ping"), ping.map { String(format: "%.0f", $0) }, "ms")
            chip(loc.t("jitter"), jitter.map { String(format: "%.1f", $0) }, "ms")
            chip(loc.t("packet_loss"), loss.map { String(format: "%.0f", $0 * 100) }, "%")
        }
    }

    private func chip(_ label: String, _ value: String?, _ unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .kerning(0.5)
                .foregroundColor(.npTextSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value ?? "—")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.npTextPrimary)
                    .contentTransition(.numericText())
                Text(unit)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.npTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassCard(cornerRadius: 14)
    }
}
