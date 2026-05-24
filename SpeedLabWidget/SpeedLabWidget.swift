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
        SpeedEntry(date: Date(), snapshot: nil, isPro: true, recent: [])
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

struct SpeedLabWidgetEntryView: View {
    var entry: SpeedEntry
    var body: some View {
        if #available(iOS 17.0, *) {
            Text("SpeedLab")
                .containerBackground(Color.npBackground, for: .widget)
        } else {
            ZStack {
                Color.npBackground
                Text("SpeedLab")
            }
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
