import SwiftUI

/// Ana ekran (A taslağı): başlık + durum, telemetri şeridi, kokpit kadranı, canlı akış grafiği,
/// test bitince kayarak gelen bağlamlı sonuç kartları, ağ bilgisi ve paylaşım.
struct SpeedTestView: View {
    @EnvironmentObject var vm: SpeedTestViewModel
    @EnvironmentObject var storeVM: StoreViewModel
    @EnvironmentObject var historyVM: HistoryViewModel
    @StateObject private var loc = LocalizationService.shared
    @State private var showShareFormatDialog = false

    var body: some View {
        ZStack {
            AuroraBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header

                    TelemetryStrip(ping: vm.phase == .idle ? nil : vm.ping,
                                   jitter: vm.phase == .idle ? nil : vm.jitter,
                                   loss: vm.packetLoss)
                        .padding(.horizontal, 20)

                    DialGaugeView(
                        speed: currentDisplaySpeed,
                        phase: vm.phase,
                        isUploading: isUploading,
                        idleTitle: loc.t("start_test")
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if vm.phase == .idle || vm.phase == .completed {
                            Task { await vm.startTest() }
                        }
                    }
                    .padding(.top, -6)

                    flowGraph
                        .padding(.horizontal, 20)

                    if vm.showResultCards, vm.phase == .completed {
                        resultCards
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Spacer(minLength: 30)
                }
            }
        }
        .confirmationDialog(loc.t("share_format_title"), isPresented: $showShareFormatDialog, titleVisibility: .visible) {
            Button(loc.t("share_format_square")) { presentShare(format: .square) }
            Button(loc.t("share_format_story")) { presentShare(format: .story) }
            Button("İptal / Cancel", role: .cancel) {}
        }
    }

    // MARK: - Parçalar

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            (Text("Speed").font(.system(size: 28, weight: .bold)) +
             Text("Lab").font(.system(size: 28, weight: .bold)).foregroundColor(.npCyan))
                .foregroundColor(.npTextPrimary)
            Text(statusLine)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.npTextSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var flowGraph: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text((vm.phase == .completed || vm.phase == .idle ? loc.t("last_30s") : loc.t("live_flow")).uppercased())
                    .foregroundColor(.npTextSecondary)
                Text("·").foregroundColor(.npTextSecondary)
                Text(loc.t("download").uppercased()).foregroundColor(.npCyan)
                if !vm.uploadSamples.values.isEmpty {
                    Text("·").foregroundColor(.npTextSecondary)
                    Text(loc.t("upload").uppercased()).foregroundColor(.npPurple)
                }
            }
            .font(.system(size: 10, weight: .semibold))
            .kerning(0.5)
            LiveFlowGraph(download: graphDownload, upload: graphUpload, height: 96)
        }
        .padding(12)
        .glassCard(cornerRadius: 18)
    }

    private var resultCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ContextResultCard(icon: "arrow.down.circle.fill", label: loc.t("download"),
                                  value: String(format: "%.1f", vm.downloadSpeed), unit: "Mbps", color: .npCyan,
                                  context: contextText(.download, vm.downloadSpeed), contextColor: contextColor(.download, vm.downloadSpeed))
                ContextResultCard(icon: "arrow.up.circle.fill", label: loc.t("upload"),
                                  value: String(format: "%.1f", vm.uploadSpeed), unit: "Mbps", color: .npPurple,
                                  context: contextText(.upload, vm.uploadSpeed), contextColor: contextColor(.upload, vm.uploadSpeed))
            }
            HStack(spacing: 12) {
                ContextResultCard(icon: "bolt.circle.fill", label: loc.t("ping"),
                                  value: String(format: "%.0f", vm.ping), unit: "ms", color: .npGreen,
                                  context: loc.t(SpeedContext.bandKey(.ping, value: vm.ping)), contextColor: .npTextSecondary)
                ContextResultCard(icon: "waveform.circle.fill", label: loc.t("jitter"),
                                  value: String(format: "%.1f", vm.jitter), unit: "ms", color: .npOrange,
                                  context: nil)
            }

            VStack(spacing: 0) {
                InfoRow(label: loc.t("isp"), value: vm.networkInfo.isp)
                Divider().background(Color.npBorder)
                InfoRow(label: loc.t("ip_address"), value: vm.networkInfo.ipAddress)
                Divider().background(Color.npBorder)
                InfoRow(label: loc.t("network"), value: vm.networkInfo.ssid)
            }
            .glassCard(cornerRadius: 16)

            Button {
                showShareFormatDialog = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text(loc.t("share_result"))
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.npCyan)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .glassCard(cornerRadius: 12, tint: .npCyan)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Türetilmiş değerler

    private var isUploading: Bool { vm.phase == .testingUpload || vm.phase == .preparingUpload }

    private var currentDisplaySpeed: Double {
        switch vm.phase {
        case .testingDownload, .preparingDownload: return vm.downloadSpeed
        case .testingUpload, .preparingUpload: return vm.uploadSpeed
        case .completed: return vm.downloadSpeed
        default: return 0
        }
    }

    /// Boşta son testin eğrisi; test sırasında canlı tampon.
    private var graphDownload: [Double] {
        if vm.phase == .idle { return historyVM.lastSamples(download: true) }
        return vm.downloadSamples.values
    }

    private var graphUpload: [Double] {
        if vm.phase == .idle { return historyVM.lastSamples(download: false) }
        return vm.uploadSamples.values
    }

    private var statusLine: String {
        var parts: [String] = []
        switch vm.phase {
        case .idle: parts.append(loc.t("start_test"))
        case .testingPing, .preparingPing: parts.append(loc.t("testing_ping"))
        case .testingDownload, .preparingDownload: parts.append(loc.t("measuring_download"))
        case .testingUpload, .preparingUpload: parts.append(loc.t("measuring_upload"))
        case .completed: parts.append(loc.t("completed"))
        }
        if vm.networkInfo.isp != "-" && !vm.networkInfo.isp.isEmpty { parts.append(Self.shortISP(vm.networkInfo.isp)) }
        if let kind = vm.connectionKind { parts.append(loc.t("kind_\(kind.rawValue)")) }
        return parts.joined(separator: " · ")
    }

    /// "Superonline Iletisim Hizmetleri A.S." → "Superonline Iletisim"
    static func shortISP(_ isp: String) -> String {
        let drop: Set<String> = ["a.s.", "a.ş.", "as", "aş", "inc.", "inc", "ltd.", "ltd", "llc", "gmbh", "sa", "s.a."]
        let words = isp.split(separator: " ").map(String.init).filter { !drop.contains($0.lowercased()) }
        return words.prefix(2).joined(separator: " ")
    }

    private func contextText(_ metric: SpeedContext.Metric, _ value: Double) -> String? {
        let history = historyVM.recentValues(metric, kind: vm.connectionKind, excluding: vm.lastResult?.id)
        if let delta = SpeedContext.deltaPercent(current: value, history: history) {
            if delta == 0 { return loc.t("context_avg") }
            let key = delta > 0 ? "context_up" : "context_down"
            return loc.t(key).replacingOccurrences(of: "{p}", with: String(abs(delta)))
        }
        return loc.t(SpeedContext.bandKey(metric, value: value))
    }

    private func contextColor(_ metric: SpeedContext.Metric, _ value: Double) -> Color {
        let history = historyVM.recentValues(metric, kind: vm.connectionKind, excluding: vm.lastResult?.id)
        if let delta = SpeedContext.deltaPercent(current: value, history: history) {
            return delta < 0 ? .npOrange : (delta == 0 ? .npTextSecondary : .npGreen)
        }
        return .npGreen
    }

    @MainActor
    private func presentShare(format: ShareCardFormat) {
        guard let result = vm.lastResult else { return }
        let caption = """
        \(loc.t("share_caption")): \(String(format: "%.1f", result.downloadSpeed)) Mbps ↓
        \(AppStoreLink.url)
        """
        var items: [Any] = [caption]
        if let image = ShareCardRenderer.render(result: result, format: format) {
            items.insert(image, at: 0)
        }
        let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            av.popoverPresentationController?.sourceView = root.view
            av.popoverPresentationController?.sourceRect = CGRect(x: root.view.bounds.midX,
                                                                  y: root.view.bounds.midY,
                                                                  width: 0, height: 0)
            av.popoverPresentationController?.permittedArrowDirections = []
            root.present(av, animated: true)
        }
    }
}

// MARK: - Subviews

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.npTextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.npTextPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
