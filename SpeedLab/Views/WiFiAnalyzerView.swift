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

                    // WiFi bağlantı durumu (gerçek)
                    ZStack {
                        Circle()
                            .fill(Color.npSurface)
                            .frame(width: 120, height: 120)
                        Image(systemName: isConnected ? "wifi" : "wifi.slash")
                            .font(.system(size: 44))
                            .foregroundStyle(
                                LinearGradient(colors: isConnected ? [.npCyan, .npBlue] : [.npTextSecondary, .npTextSecondary.opacity(0.6)],
                                               startPoint: .top, endPoint: .bottom)
                            )
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
