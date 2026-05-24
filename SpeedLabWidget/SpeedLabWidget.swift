import WidgetKit
import SwiftUI

struct SpeedEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
    let isPro: Bool
    let recent: [Double]
}

struct SpeedProvider: TimelineProvider {
    func placeholder(in context: Context) -> SpeedEntry {
        SpeedEntry(date: Date(), snapshot: nil, isPro: false, recent: [])
    }
    func getSnapshot(in context: Context, completion: @escaping (SpeedEntry) -> Void) {
        completion(currentEntry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SpeedEntry>) -> Void) {
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }
    private func currentEntry() -> SpeedEntry {
        let store = SharedStore()
        return SpeedEntry(date: Date(), snapshot: store.loadSnapshot(), isPro: store.isPro(), recent: store.recentDownloads())
    }
}

private struct WidgetBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(Color.npBackground, for: .widget)
        } else {
            content.background(Color.npBackground)
        }
    }
}

struct SpeedLabWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: SpeedEntry
    private let loc = LocalizationService.shared

    var body: some View {
        Group {
            content
        }
        .modifier(WidgetBackground())
        .widgetURL(URL(string: entry.isPro ? "speedlab://open" : "speedlab://pro"))
    }

    @ViewBuilder private var content: some View {
        if !entry.isPro {
            upsell
        } else if let snap = entry.snapshot {
            switch family {
            case .systemSmall:  small(snap)
            case .systemLarge:  large(snap)
            default:            medium(snap)
            }
        } else {
            empty
        }
    }

    private var upsell: some View {
        VStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.system(size: 30))
                .foregroundStyle(LinearGradient.npMain)
            Text(loc.t("widget_pro_title"))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text(loc.t("widget_pro_sub"))
                .font(.system(size: 12))
                .foregroundColor(.npTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var empty: some View {
        VStack(spacing: 8) {
            Image(systemName: "gauge.high").font(.system(size: 26)).foregroundStyle(LinearGradient.npMain)
            Text(loc.t("widget_empty"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.npTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func relative(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: loc.language == .tr ? "tr_TR" : "en_US")
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }

    private func small(_ s: WidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "gauge.high").font(.system(size: 13)).foregroundStyle(LinearGradient.npMain)
                Text("SpeedLab").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
            }
            Spacer()
            Text(String(format: "%.0f", s.download))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(LinearGradient.npMain)
            Text("Mbps ↓").font(.system(size: 11, weight: .semibold)).foregroundColor(.npTextSecondary)
            Spacer()
            Text("↑\(String(format: "%.0f", s.upload)) · \(String(format: "%.0f", s.ping))ms")
                .font(.system(size: 11)).foregroundColor(.npTextSecondary)
            Text(relative(s.date)).font(.system(size: 10)).foregroundColor(.npTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(12)
    }

    private func medium(_ s: WidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "gauge.high").font(.system(size: 15)).foregroundStyle(LinearGradient.npMain)
                    Text("SpeedLab").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                }
                Spacer()
                Text(relative(s.date)).font(.system(size: 11)).foregroundColor(.npTextSecondary)
            }
            HStack(spacing: 18) {
                metric("\(String(format: "%.0f", s.download))", "↓ Mbps", .npCyan)
                metric("\(String(format: "%.0f", s.upload))", "↑ Mbps", .npPurple)
                metric("\(String(format: "%.0f", s.ping))", "ms", .npGreen)
                metric("\(String(format: "%.0f", s.jitter))", "jit", .npOrange)
            }
            if !s.isp.isEmpty {
                Text(s.isp).font(.system(size: 12)).foregroundColor(.npTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(14)
    }

    private func large(_ s: WidgetSnapshot) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "gauge.high").font(.system(size: 16)).foregroundStyle(LinearGradient.npMain)
                Text("SpeedLab").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                Spacer()
                Text(relative(s.date)).font(.system(size: 11)).foregroundColor(.npTextSecondary)
            }
            ShareGaugeView(value: min(s.download / 200.0, 1.0), speed: s.download, diameter: 150)
            HStack(spacing: 22) {
                metric("\(String(format: "%.0f", s.upload))", "↑ Mbps", .npPurple)
                metric("\(String(format: "%.0f", s.ping))", "ms", .npCyan)
                metric("\(String(format: "%.0f", s.jitter))", "jit", .npOrange)
            }
            if !entry.recent.isEmpty {
                VStack(spacing: 4) {
                    Text(loc.t("widget_recent")).font(.system(size: 11, weight: .semibold)).foregroundColor(.npTextSecondary)
                    HStack(spacing: 16) {
                        ForEach(Array(entry.recent.enumerated()), id: \.offset) { _, dl in
                            Text("\(String(format: "%.0f", dl))↓").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
    }

    private func metric(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.white)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(color)
        }
    }
}

@main
struct SpeedLabWidget: Widget {
    let kind = "SpeedLabWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpeedProvider()) { entry in
            SpeedLabWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("SpeedLab")
        .description("Son hız testi sonucun.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
