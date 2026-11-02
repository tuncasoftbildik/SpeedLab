import SwiftUI

/// WiFi sekmesi: sinyal kalitesi kadranı, bağlantı rozeti, bilgi satırları (iOS'un vermediği alanlar dürüstçe), 60 sn sinyal grafiği.
struct WiFiAnalyzerView: View {
    @EnvironmentObject var vm: WiFiViewModel
    @EnvironmentObject var historyVM: HistoryViewModel
    @StateObject private var loc = LocalizationService.shared

    /// iOS sinyal gücü verirse o; vermezse son hız testinden bağlantı sağlığı.
    private var heroQuality: Double? {
        if let q = vm.networkInfo.signalQuality, q > 0 { return q }
        guard let last = historyVM.lastResult() else { return nil }
        return ConnectionHealth.score(ping: last.ping, jitter: last.jitter)
    }

    private var heroCaption: String {
        if let q = vm.networkInfo.signalQuality, q > 0 { return loc.t("signal_quality") }
        return historyVM.lastResult() == nil ? loc.t("health_no_test") : loc.t("health_from_last_test")
    }

    var body: some View {
        ZStack {
            AuroraBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header

                    VStack(spacing: 4) {
                        SignalQualityGauge(quality: heroQuality)
                        Text(heroCaption)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.npTextSecondary)
                    }
                    .padding(.top, 4)

                    HStack(spacing: 8) {
                        Image(systemName: connectionIcon).foregroundColor(.npCyan)
                        Text(connectionLabel)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.npTextPrimary)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .glassCard(cornerRadius: 20)

                    infoCard

                    if vm.hasSignalData {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(loc.t("signal_history").uppercased())
                                .font(.system(size: 10, weight: .semibold))
                                .kerning(0.5)
                                .foregroundColor(.npTextSecondary)
                            LiveFlowGraph(download: vm.signalHistory.map { $0.quality * 100 }, upload: [], height: 80)
                        }
                        .padding(12)
                        .glassCard(cornerRadius: 18)
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 30)
                }
            }
        }
        .task { await vm.refresh() }
        .onAppear { vm.startMonitoring() }
        .onDisappear { vm.stopMonitoring() }
    }

    private var header: some View {
        HStack {
            Text(loc.t("tab_wifi"))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.npTextPrimary)
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
                .background(Color.npCyan.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var infoCard: some View {
        VStack(spacing: 0) {
            WiFiInfoRow(icon: "wifi", label: loc.t("network_name"), value: vm.networkInfo.ssid, color: .npCyan)
            Divider().background(Color.npBorder)
            WiFiInfoRow(icon: "dot.radiowaves.left.and.right", label: loc.t("bssid"), value: shortBSSID, color: .npBlue)
            Divider().background(Color.npBorder)
            WiFiInfoRow(icon: "waveform.path", label: loc.t("band"), value: loc.t("ios_not_shared"), color: .npPurple, dimmed: true)
            Divider().background(Color.npBorder)
            WiFiInfoRow(icon: "number.square", label: loc.t("channel"), value: loc.t("ios_not_shared"), color: .npPurple, dimmed: true)
            Divider().background(Color.npBorder)
            WiFiInfoRow(icon: "network", label: loc.t("local_ip"), value: vm.networkInfo.ipAddress, color: .npBlue)
            Divider().background(Color.npBorder)
            WiFiInfoRow(icon: "globe", label: loc.t("public_ip"), value: vm.networkInfo.publicIP, color: .npGreen)
            Divider().background(Color.npBorder)
            WiFiInfoRow(icon: "building.2", label: loc.t("isp"), value: vm.networkInfo.isp, color: .npGreen)
        }
        .glassCard(cornerRadius: 16)
        .padding(.horizontal, 20)
    }

    private var shortBSSID: String {
        let b = vm.networkInfo.bssid
        guard b.count > 8, b != "-" else { return b }
        return String(b.prefix(8)) + "…"
    }

    private var connectionIcon: String {
        switch vm.networkInfo.connectionKind {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .wired: return "cable.connector"
        case nil: return "network"
        }
    }

    private var connectionLabel: String {
        var s: String
        switch vm.networkInfo.connectionKind {
        case .wifi: s = loc.t("kind_wifi")
        case .cellular: s = loc.t("kind_cellular")
        case .wired: s = loc.t("kind_wired")
        case nil: s = loc.t("unknown")
        }
        if let tech = vm.networkInfo.radioTech, vm.networkInfo.connectionKind == .cellular { s += " · \(tech)" }
        return s
    }
}

struct WiFiInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    var dimmed: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.npTextSecondary)
                Text(value)
                    .font(.system(size: 14, weight: dimmed ? .regular : .semibold))
                    .foregroundColor(dimmed ? .npTextSecondary : .npTextPrimary)
                    .italic(dimmed)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
