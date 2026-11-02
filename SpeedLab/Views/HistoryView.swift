import SwiftUI

/// Geçmiş: önce grafik (Gün/Hafta/Ay), özet çipler, filtre, altta liste (sola kaydır → sil).
struct HistoryView: View {
    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var storeVM: StoreViewModel
    @StateObject private var loc = LocalizationService.shared
    @State private var showDeleteAlert = false
    @State private var showProSheet = false
    @State private var showExportDialog = false

    var body: some View {
        ZStack {
            AuroraBackground()

            VStack(spacing: 0) {
                header

                if historyVM.results.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "gauge.with.dots.needle.0percent")
                            .font(.system(size: 48))
                            .foregroundColor(.npTextSecondary.opacity(0.5))
                        Text(loc.t("no_results"))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.npTextSecondary)
                    }
                    Spacer()
                } else {
                    List {
                        Section {
                            chartCard
                            averages
                            filters
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))

                        if !storeVM.isPro && historyVM.results.count >= 10 {
                            proLimitBanner
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                        }

                        ForEach(historyVM.filteredResults) { result in
                            HistoryCard(result: result)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) { historyVM.delete(result.id) } label: {
                                        Label(loc.t("delete"), systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .onAppear { historyVM.load(isPro: storeVM.isPro) }
        .onChange(of: storeVM.isPro) { historyVM.load(isPro: $0) }
        .alert(loc.t("delete_confirm"), isPresented: $showDeleteAlert) {
            Button(loc.t("cancel"), role: .cancel) {}
            Button(loc.t("delete_all"), role: .destructive) { historyVM.deleteAll() }
        }
        .sheet(isPresented: $showProSheet) { ProUpgradeSheet().environmentObject(storeVM) }
        .confirmationDialog(loc.t("export"), isPresented: $showExportDialog, titleVisibility: .visible) {
            Button(loc.t("export_csv")) { exportCSV() }
            Button(loc.t("export_pdf")) { exportPDF() }
            Button(loc.t("cancel"), role: .cancel) {}
        }
    }

    // MARK: - Dışa aktarma (Pro)

    private func exportCSV() {
        let data = Data(ExportService.csv(historyVM.allResults()).utf8)
        ShareSheet.presentFile(data: data, name: ExportService.fileName(kind: "csv", range: historyVM.range, now: Date()))
    }

    @MainActor
    private func exportPDF() {
        let rows = historyVM.chartResults(isPro: true)
        let chartImage = ImageRenderer(content: HistoryChartView(results: rows)
            .frame(width: 515, height: 170).padding(8).background(Color.npBrandBackground)
            .environment(\.colorScheme, .dark)).uiImage
        let data = ExportService.pdf(results: rows, range: historyVM.range, chart: chartImage, title: loc.t("export_title"))
        ShareSheet.presentFile(data: data, name: ExportService.fileName(kind: "pdf", range: historyVM.range, now: Date()))
    }

    // MARK: - Parçalar

    private var header: some View {
        HStack {
            Text(loc.t("test_history"))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.npTextPrimary)
            Spacer()
            if !historyVM.results.isEmpty {
                Button {
                    if storeVM.isPro { showExportDialog = true } else { showProSheet = true }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text(loc.t("export"))
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.npCyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.npCyan.opacity(0.12))
                    .clipShape(Capsule())
                }
                Button { showDeleteAlert = true } label: {
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
        .padding(.bottom, 8)
    }

    private var chartCard: some View {
        VStack(spacing: 10) {
            HStack {
                Picker("", selection: Binding(
                    get: { historyVM.range },
                    set: { r in
                        if !historyVM.requestRange(r, isPro: storeVM.isPro) { showProSheet = true }
                    })) {
                    ForEach(HistoryRange.allCases, id: \.self) { r in
                        Text(loc.t(r.localizationKey)).tag(r)
                    }
                }
                .pickerStyle(.segmented)
            }
            HistoryChartView(results: historyVM.chartResults(isPro: storeVM.isPro))
            if !storeVM.isPro {
                Text(loc.t("free_chart_note"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.npTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .glassCard(cornerRadius: 18)
    }

    private var averages: some View {
        HStack(spacing: 8) {
            AverageChip(label: "↓", value: String(format: "%.0f", historyVM.averageDownload), color: .npCyan)
            AverageChip(label: "↑", value: String(format: "%.0f", historyVM.averageUpload), color: .npPurple)
            AverageChip(label: "ms", value: String(format: "%.0f", historyVM.averagePing), color: .npGreen)
            Spacer()
            Text("\(historyVM.results.count) \(loc.t("tab_speed").lowercased())")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.npTextSecondary)
        }
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: loc.t("filter_all"), selected: historyVM.kind == nil && historyVM.carrier == nil) {
                    historyVM.kind = nil; historyVM.carrier = nil
                }
                FilterChip(title: loc.t("filter_wifi"), selected: historyVM.kind == .wifi) { historyVM.kind = .wifi }
                FilterChip(title: loc.t("filter_cellular"), selected: historyVM.kind == .cellular) { historyVM.kind = .cellular }
                ForEach(historyVM.carriers, id: \.self) { c in
                    FilterChip(title: c, selected: historyVM.carrier == c) {
                        historyVM.carrier = historyVM.carrier == c ? nil : c
                    }
                }
            }
        }
    }

    private var proLimitBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "crown.fill").foregroundColor(.npOrange)
            Text(loc.t("pro_limit"))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.npTextSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.npOrange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct FilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(selected ? .npBrandTextPrimary : .npTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(selected ? Color.npPrimary : Color.npSurface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
                .monospacedDigit()
                .foregroundColor(.npTextPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.npSurface)
        .clipShape(Capsule())
    }
}

struct HistoryCard: View {
    let result: SpeedTestResult

    private var kindIcon: String {
        switch result.effectiveKind {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .wired: return "cable.connector"
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: kindIcon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.npCyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.effectiveKind == .wifi && !result.ssid.isEmpty && result.ssid != "-" ? result.ssid : (result.carrier ?? result.isp))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.npTextPrimary)
                        .lineLimit(1)
                    Text(result.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.npTextSecondary)
                }
                Spacer()
                Text(result.carrier ?? result.isp)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.npTextSecondary)
                    .lineLimit(1)
            }

            HStack(spacing: 16) {
                metric("arrow.down", result.downloadSpeed, "Mbps", .npCyan, "%.1f")
                metric("arrow.up", result.uploadSpeed, "Mbps", .npPurple, "%.1f")
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill").font(.system(size: 10)).foregroundColor(.npGreen)
                    Text(String(format: "%.0f ms", result.ping))
                        .font(.system(size: 13, weight: .semibold))
                        .monospacedDigit()
                        .foregroundColor(.npTextSecondary)
                }
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 14)
    }

    private func metric(_ icon: String, _ v: Double, _ unit: String, _ color: Color, _ fmt: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10, weight: .bold)).foregroundColor(color)
            Text(String(format: fmt, v))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.npTextPrimary)
            Text(unit).font(.system(size: 10)).foregroundColor(.npTextSecondary)
        }
    }
}
