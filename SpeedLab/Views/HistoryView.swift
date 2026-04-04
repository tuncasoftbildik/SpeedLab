import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var storeVM: StoreViewModel
    @StateObject private var loc = LocalizationService.shared
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            Color.npBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(loc.t("test_history"))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if !historyVM.results.isEmpty {
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(.npRed)
                                .padding(8)
                                .background(Color.npRed.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)

                if historyVM.results.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "gauge.with.dots.needle.0percent")
                            .font(.system(size: 48))
                            .foregroundColor(.npSurfaceLight)
                        Text(loc.t("no_results"))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.npTextSecondary)
                    }
                    Spacer()
                } else {
                    // Averages bar
                    HStack(spacing: 8) {
                        AverageChip(label: "↓", value: String(format: "%.0f", historyVM.averageDownload), color: .npCyan)
                        AverageChip(label: "↑", value: String(format: "%.0f", historyVM.averageUpload), color: .npPurple)
                        AverageChip(label: "ms", value: String(format: "%.0f", historyVM.averagePing), color: .npGreen)
                        Spacer()
                        Text("\(historyVM.results.count) \(loc.t("tab_speed").lowercased())")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.npTextSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                    // Pro limit banner
                    if !storeVM.isPro && historyVM.results.count >= 10 {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.npOrange)
                            Text(loc.t("pro_limit"))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.npTextSecondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.npOrange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    }

                    // List
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 8) {
                            ForEach(historyVM.results) { result in
                                HistoryCard(result: result)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            historyVM.delete(result.id)
                                        } label: {
                                            Label(loc.t("delete"), systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .onAppear { historyVM.load(isPro: storeVM.isPro) }
        .alert(loc.t("delete_confirm"), isPresented: $showDeleteAlert) {
            Button(loc.t("cancel"), role: .cancel) {}
            Button(loc.t("delete_all"), role: .destructive) {
                historyVM.deleteAll()
            }
        }
    }
}

struct AverageChip: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.npSurface)
        .clipShape(Capsule())
    }
}

struct HistoryCard: View {
    let result: SpeedTestResult

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.ssid.isEmpty ? "WiFi" : result.ssid)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Text(result.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.npTextSecondary)
                }
                Spacer()
                Text(result.isp)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.npTextSecondary)
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.npCyan)
                    Text(String(format: "%.1f", result.downloadSpeed))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Mbps")
                        .font(.system(size: 10))
                        .foregroundColor(.npTextSecondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.npPurple)
                    Text(String(format: "%.1f", result.uploadSpeed))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Mbps")
                        .font(.system(size: 10))
                        .foregroundColor(.npTextSecondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.npGreen)
                    Text(String(format: "%.0f ms", result.ping))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.npTextSecondary)
                }
            }
        }
        .padding(14)
        .background(Color.npSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
