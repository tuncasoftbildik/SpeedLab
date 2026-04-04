import SwiftUI

struct SpeedTestView: View {
    @EnvironmentObject var vm: SpeedTestViewModel
    @EnvironmentObject var storeVM: StoreViewModel
    @StateObject private var loc = LocalizationService.shared
    @State private var glowPulse = false
    @State private var showRewardAlert = false

    var body: some View {
        ZStack {
            Color.npBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Speed")
                                .font(.system(size: 28, weight: .bold)) +
                            Text("Lab")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.npCyan)
                            Text(phaseText)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.npTextSecondary)
                        }
                        Spacer()
                        // Network badge
                        if !vm.networkInfo.ssid.isEmpty && vm.networkInfo.ssid != "-" {
                            HStack(spacing: 4) {
                                Image(systemName: "wifi")
                                    .font(.system(size: 10))
                                Text(vm.networkInfo.ssid)
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(.npCyan)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.npCyan.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Gauge
                    ZStack {
                        // Completion glow effect
                        if vm.showCompletionEffect {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.npCyan, .npGreen, .npCyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                                .frame(width: 260, height: 260)
                                .scaleEffect(glowPulse ? 1.08 : 1.0)
                                .opacity(glowPulse ? 0.0 : 0.8)
                                .animation(
                                    .easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                                    value: glowPulse
                                )

                            Circle()
                                .stroke(Color.npCyan.opacity(0.3), lineWidth: 1.5)
                                .frame(width: 280, height: 280)
                                .scaleEffect(glowPulse ? 1.15 : 1.0)
                                .opacity(glowPulse ? 0.0 : 0.5)
                                .animation(
                                    .easeInOut(duration: 1.8).repeatForever(autoreverses: false),
                                    value: glowPulse
                                )
                        }

                        SpeedGaugeView(
                            value: vm.gaugeValue,
                            speed: currentDisplaySpeed,
                            phase: vm.phase
                        )
                    }
                    .onTapGesture {
                        if vm.phase == .idle || vm.phase == .completed {
                            Task { await vm.startTest() }
                        }
                    }
                    .onChange(of: vm.showCompletionEffect) { newValue in
                        if newValue {
                            glowPulse = true
                        } else {
                            glowPulse = false
                        }
                    }

                    // Phase indicator
                    if vm.phase != .idle && vm.phase != .completed {
                        ProgressView(value: vm.progress)
                            .tint(.npCyan)
                            .padding(.horizontal, 40)
                    }

                    if vm.phase == .idle {
                        Text(loc.t("tap_to_start"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.npTextSecondary)
                    }

                    // Completion badge
                    if vm.showCompletionEffect {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.npGreen)
                            Text(loc.t("completed"))
                                .foregroundColor(.npGreen)
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Result cards
                    if vm.phase == .completed || vm.downloadSpeed > 0 {
                        HStack(spacing: 12) {
                            ResultCard(
                                icon: "arrow.down.circle.fill",
                                label: loc.t("download"),
                                value: String(format: "%.1f", vm.downloadSpeed),
                                unit: "Mbps",
                                color: .npCyan
                            )
                            ResultCard(
                                icon: "arrow.up.circle.fill",
                                label: loc.t("upload"),
                                value: String(format: "%.1f", vm.uploadSpeed),
                                unit: "Mbps",
                                color: .npPurple
                            )
                        }
                        .padding(.horizontal, 20)

                        HStack(spacing: 12) {
                            ResultCard(
                                icon: "bolt.circle.fill",
                                label: loc.t("ping"),
                                value: String(format: "%.0f", vm.ping),
                                unit: "ms",
                                color: .npGreen
                            )
                            ResultCard(
                                icon: "waveform.circle.fill",
                                label: loc.t("jitter"),
                                value: String(format: "%.1f", vm.jitter),
                                unit: "ms",
                                color: .npOrange
                            )
                        }
                        .padding(.horizontal, 20)
                    }

                    // Network info
                    if vm.phase == .completed {
                        VStack(spacing: 0) {
                            InfoRow(label: loc.t("isp"), value: vm.networkInfo.isp)
                            Divider().background(Color.npBorder)
                            InfoRow(label: loc.t("ip_address"), value: vm.networkInfo.ipAddress)
                            Divider().background(Color.npBorder)
                            InfoRow(label: loc.t("network"), value: vm.networkInfo.ssid)
                        }
                        .background(Color.npSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)

                        // Share button
                        Button {
                            shareResult()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text(loc.t("share_result"))
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.npCyan)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.npCyan.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 20)

                        // Rewarded ad button (sadece ücretsiz kullanıcılar)
                        if !storeVM.isPro {
                            Button {
                                AdManager.shared.showRewarded { rewarded in
                                    if rewarded {
                                        showRewardAlert = true
                                    }
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.circle.fill")
                                    Text(loc.t("watch_ad_extra_test"))
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.npOrange)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.npOrange.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .alert(loc.t("reward_earned"), isPresented: $showRewardAlert) {
            Button("OK") {
                Task { await vm.startTest() }
            }
        }
    }

    private var currentDisplaySpeed: Double {
        switch vm.phase {
        case .testingDownload: return vm.downloadSpeed
        case .testingUpload: return vm.uploadSpeed
        default: return max(vm.downloadSpeed, vm.uploadSpeed)
        }
    }

    private var phaseText: String {
        switch vm.phase {
        case .idle: return loc.t("start_test")
        case .testingPing, .preparingPing: return loc.t("testing_ping")
        case .testingDownload, .preparingDownload: return loc.t("testing_download")
        case .testingUpload, .preparingUpload: return loc.t("testing_upload")
        case .completed: return loc.t("completed")
        }
    }

    private func shareResult() {
        guard let result = vm.lastResult else { return }
        let text = """
        SpeedLab - Speed Test
        ⬇️ Download: \(String(format: "%.1f", result.downloadSpeed)) Mbps
        ⬆️ Upload: \(String(format: "%.1f", result.uploadSpeed)) Mbps
        📡 Ping: \(String(format: "%.0f", result.ping)) ms
        🌐 ISP: \(result.isp)
        """
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(av, animated: true)
        }
    }
}

// MARK: - Subviews
struct ResultCard: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.npTextSecondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(unit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.npTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.npSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

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
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
