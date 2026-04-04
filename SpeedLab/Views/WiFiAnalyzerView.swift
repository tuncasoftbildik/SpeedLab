import SwiftUI

struct WiFiAnalyzerView: View {
    @EnvironmentObject var vm: WiFiViewModel
    @StateObject private var loc = LocalizationService.shared

    var body: some View {
        ZStack {
            Color.npBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Text(loc.t("tab_wifi"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Button {
                            Task { await vm.refresh() }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                Text(loc.t("refresh"))
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.npCyan)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.npCyan.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Signal strength circle
                    ZStack {
                        Circle()
                            .fill(Color.npSurface)
                            .frame(width: 180, height: 180)

                        Circle()
                            .stroke(Color.npSurfaceLight, lineWidth: 8)
                            .frame(width: 160, height: 160)

                        Circle()
                            .trim(from: 0, to: signalPercent)
                            .stroke(signalColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 160, height: 160)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 4) {
                            Image(systemName: "wifi")
                                .font(.system(size: 32))
                                .foregroundStyle(
                                    LinearGradient(colors: [signalColor, signalColor.opacity(0.6)],
                                                   startPoint: .top, endPoint: .bottom)
                                )
                            Text(signalLabel)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(signalColor)
                        }
                    }
                    .padding(.vertical, 8)

                    // Connection type badge
                    HStack(spacing: 8) {
                        Image(systemName: connectionIcon)
                            .foregroundColor(.npCyan)
                        Text(vm.connectionType)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.npSurface)
                    .clipShape(Capsule())

                    // Info cards
                    VStack(spacing: 0) {
                        WiFiInfoRow(icon: "wifi", label: loc.t("network_name"), value: vm.networkInfo.ssid, color: .npCyan)
                        Divider().background(Color.npBorder)
                        WiFiInfoRow(icon: "antenna.radiowaves.left.and.right", label: loc.t("connection_type"), value: vm.connectionType, color: .npPurple)
                        Divider().background(Color.npBorder)
                        WiFiInfoRow(icon: "number", label: loc.t("local_ip"), value: vm.networkInfo.ipAddress, color: .npBlue)
                        Divider().background(Color.npBorder)
                        WiFiInfoRow(icon: "building.2", label: loc.t("isp"), value: vm.networkInfo.isp, color: .npGreen)
                    }
                    .background(Color.npSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
        }
        .task { await vm.refresh() }
    }

    private var isConnected: Bool {
        vm.networkInfo.ssid != "-" && !vm.networkInfo.ssid.isEmpty
    }

    private var signalPercent: Double {
        guard isConnected else { return 0 }
        // WiFi bağlıysa connection type'a göre değerlendir
        if vm.connectionType == "WiFi" { return 0.85 }
        if vm.connectionType == "Ethernet" { return 1.0 }
        return 0.5
    }

    private var signalColor: Color {
        let p = signalPercent
        if p >= 0.7 { return .npGreen }
        if p >= 0.4 { return .npOrange }
        if p > 0 { return .npRed }
        return .npTextSecondary
    }

    private var signalLabel: String {
        guard isConnected else { return loc.t("weak") }
        let p = signalPercent
        if p >= 0.7 { return loc.t("excellent") }
        if p >= 0.4 { return loc.t("good") }
        if p >= 0.2 { return loc.t("fair") }
        return loc.t("weak")
    }

    private var connectionIcon: String {
        switch vm.connectionType {
        case "WiFi": return "wifi"
        case "Hücresel", "Cellular": return "antenna.radiowaves.left.and.right"
        default: return "network"
        }
    }
}

struct WiFiInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.npTextSecondary)
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
