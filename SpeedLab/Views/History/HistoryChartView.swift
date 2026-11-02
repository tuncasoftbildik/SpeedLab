import SwiftUI
import Charts

/// Geçmiş grafiği: indirme (cyan alan + çizgi), yükleme (mor çizgi), ping soluk (ikinci ölçek: ms/10).
struct HistoryChartView: View {
    let results: [SpeedTestResult]
    @StateObject private var loc = LocalizationService.shared

    var body: some View {
        if results.isEmpty {
            Text(loc.t("no_results"))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.npTextSecondary)
                .frame(maxWidth: .infinity, minHeight: 160)
        } else {
            Chart {
                ForEach(results) { r in
                    AreaMark(x: .value("t", r.date), y: .value("dl", r.downloadSpeed))
                        .foregroundStyle(LinearGradient(colors: [Color.npCyan.opacity(0.35), Color.npCyan.opacity(0)],
                                                        startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.catmullRom)
                    LineMark(x: .value("t", r.date), y: .value("dl", r.downloadSpeed), series: .value("s", "dl"))
                        .foregroundStyle(Color.npCyan)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                    LineMark(x: .value("t", r.date), y: .value("ul", r.uploadSpeed), series: .value("s", "ul"))
                        .foregroundStyle(Color.npPurple)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    LineMark(x: .value("t", r.date), y: .value("ping", r.ping / 10), series: .value("s", "ping"))
                        .foregroundStyle(Color.npTextSecondary.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    if results.count == 1 {
                        PointMark(x: .value("t", r.date), y: .value("dl", r.downloadSpeed))
                            .foregroundStyle(Color.npCyan)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Color.npTextSecondary.opacity(0.15))
                    AxisValueLabel().foregroundStyle(Color.npTextSecondary).font(.system(size: 10))
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel().foregroundStyle(Color.npTextSecondary).font(.system(size: 10))
                }
            }
            .frame(height: 160)
        }
    }
}
