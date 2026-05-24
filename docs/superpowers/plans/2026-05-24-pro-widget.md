# Pro Home-Screen Widget Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the advertised "Home screen widget" Pro perk — a WidgetKit widget (small/medium/large) showing the last speed test, Pro-gated with an upsell state for free users.

**Architecture:** App and a new WidgetKit extension share a `WidgetSnapshot` model + `SharedStore` (App Group `group.com.vialab.speedlab`). The app writes the latest snapshot + `isPro` on each test/entitlement change and calls `WidgetCenter.reloadAllTimelines()`. The widget's `TimelineProvider` reads the shared store. Tapping the upsell opens `speedlab://pro` → the app presents the paywall.

**Tech Stack:** SwiftUI, WidgetKit, App Groups (shared UserDefaults), xcodegen, XCTest.

**Constraint:** Do NOT archive/upload a new App Store build while v1.0.2 (build 6) is in review. Local simulator build/test + commits only. App Group + widget app IDs need Apple Developer portal provisioning before an App Store build (not for simulator).

---

## File Structure

- `SpeedLab/App/SpeedLab.entitlements` (modify) — add App Group.
- `SpeedLab/WidgetShared/WidgetSnapshot.swift` (new) — Codable snapshot model. In both targets.
- `SpeedLab/WidgetShared/SharedStore.swift` (new) — App Group UserDefaults read/write. In both targets.
- `SpeedLab/Services/HistoryService.swift` (modify) — write snapshot + reload on save.
- `SpeedLab/ViewModels/StoreViewModel.swift` (modify) — write isPro + reload on change.
- `SpeedLab/Services/LocalizationService.swift` (modify) — widget strings.
- `SpeedLab/App/SpeedLabApp.swift` (modify) — `onOpenURL` → paywall sheet.
- `SpeedLabWidget/SpeedLabWidget.swift` (new) — Provider + EntryView + `@main` widget.
- `SpeedLabWidget/SpeedLabWidget.entitlements` (new) — App Group.
- `project.yml` (modify) — URL scheme, widget target, embed, shared sources, app-group on app.
- `SpeedLabTests/SharedStoreTests.swift` (new) — round-trip tests.

---

### Task 1: Shared model + store (App Group)

**Files:**
- Create: `SpeedLab/WidgetShared/WidgetSnapshot.swift`
- Create: `SpeedLab/WidgetShared/SharedStore.swift`
- Modify: `SpeedLab/App/SpeedLab.entitlements`
- Test: `SpeedLabTests/SharedStoreTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
// SpeedLabTests/SharedStoreTests.swift
import XCTest
@testable import SpeedLab

final class SharedStoreTests: XCTestCase {
    private func tempStore() -> SharedStore {
        let suite = "test.sharedstore.\(UUID().uuidString)"
        return SharedStore(defaults: UserDefaults(suiteName: suite)!)
    }

    func test_snapshotRoundTrip() {
        let store = tempStore()
        let snap = WidgetSnapshot(download: 38.2, upload: 12.4, ping: 14, jitter: 2, isp: "Turknet", date: Date(timeIntervalSince1970: 1_000_000))
        store.save(snap)
        XCTAssertEqual(store.loadSnapshot(), snap)
    }

    func test_emptyByDefault() {
        XCTAssertNil(tempStore().loadSnapshot())
    }

    func test_proFlag() {
        let store = tempStore()
        XCTAssertFalse(store.isPro())
        store.setPro(true)
        XCTAssertTrue(store.isPro())
    }

    func test_recentDownloads() {
        let store = tempStore()
        store.saveRecent([35, 41, 29])
        XCTAssertEqual(store.recentDownloads(), [35, 41, 29])
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd ~/SpeedLab && xcodebuild test -project SpeedLab.xcodeproj -scheme SpeedLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SpeedLabTests/SharedStoreTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -8`
Expected: build failure — `cannot find 'SharedStore' in scope`.

- [ ] **Step 3: Implement the model + store**

```swift
// SpeedLab/WidgetShared/WidgetSnapshot.swift
import Foundation

struct WidgetSnapshot: Codable, Equatable {
    let download: Double
    let upload: Double
    let ping: Double
    let jitter: Double
    let isp: String
    let date: Date
}
```

```swift
// SpeedLab/WidgetShared/SharedStore.swift
import Foundation

enum AppGroup {
    static let id = "group.com.vialab.speedlab"
}

struct SharedStore {
    private let defaults: UserDefaults
    private let snapshotKey = "widget_snapshot"
    private let proKey = "widget_is_pro"
    private let recentKey = "widget_recent_downloads"

    init(defaults: UserDefaults? = UserDefaults(suiteName: AppGroup.id)) {
        self.defaults = defaults ?? .standard
    }

    func save(_ snapshot: WidgetSnapshot) {
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: snapshotKey)
        }
    }

    func loadSnapshot() -> WidgetSnapshot? {
        guard let data = defaults.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func setPro(_ isPro: Bool) { defaults.set(isPro, forKey: proKey) }
    func isPro() -> Bool { defaults.bool(forKey: proKey) }

    func saveRecent(_ downloads: [Double]) { defaults.set(downloads, forKey: recentKey) }
    func recentDownloads() -> [Double] { (defaults.array(forKey: recentKey) as? [Double]) ?? [] }
}
```

- [ ] **Step 4: Add the App Group to the app entitlements**

Replace `SpeedLab/App/SpeedLab.entitlements` with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.networking.HotspotConfiguration</key>
	<true/>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.com.vialab.speedlab</string>
	</array>
</dict>
</plist>
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd ~/SpeedLab && xcodegen generate && xcodebuild test -project SpeedLab.xcodeproj -scheme SpeedLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SpeedLabTests/SharedStoreTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add SpeedLab/WidgetShared SpeedLab/App/SpeedLab.entitlements SpeedLabTests/SharedStoreTests.swift SpeedLab.xcodeproj
git commit -m "feat: WidgetSnapshot + SharedStore (App Group) for widget data sharing"
```

---

### Task 2: App writes to the shared store

The app must populate the shared store so the widget has data.

**Files:**
- Modify: `SpeedLab/Services/HistoryService.swift`
- Modify: `SpeedLab/ViewModels/StoreViewModel.swift`

- [ ] **Step 1: Sync the widget when a result is saved**

In `HistoryService.swift`, add `import WidgetKit` at the top. In `func save(_ result: SpeedTestResult)`, after the existing `UserDefaults.standard.set(data, forKey: key)` write, call `syncWidget(history)`. Add this method to the class:

```swift
    func syncWidget(_ history: [SpeedTestResult]) {
        let store = SharedStore()
        if let latest = history.first {
            store.save(WidgetSnapshot(
                download: latest.downloadSpeed,
                upload: latest.uploadSpeed,
                ping: latest.ping,
                jitter: latest.jitter,
                isp: latest.isp,
                date: latest.date
            ))
        }
        store.saveRecent(Array(history.prefix(3).map { $0.downloadSpeed }))
        WidgetCenter.shared.reloadAllTimelines()
    }
```

So `save` becomes:

```swift
    func save(_ result: SpeedTestResult) {
        var history = loadAll()
        history.insert(result, at: 0)
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: key)
        }
        syncWidget(history)
    }
```

- [ ] **Step 2: Mirror the Pro flag into the shared store**

In `StoreViewModel.swift`, add `import WidgetKit` at the top. Change the `isPro` property to push changes to the shared store:

```swift
    @Published var isPro = false {
        didSet {
            SharedStore().setPro(isPro)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
```

- [ ] **Step 3: Build to verify it compiles**

Run: `cd ~/SpeedLab && xcodebuild build -project SpeedLab.xcodeproj -scheme SpeedLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add SpeedLab/Services/HistoryService.swift SpeedLab/ViewModels/StoreViewModel.swift
git commit -m "feat: app writes snapshot + isPro to shared store on save/entitlement change"
```

---

### Task 3: Localization strings for the widget

**Files:**
- Modify: `SpeedLab/Services/LocalizationService.swift`

- [ ] **Step 1: Add widget strings**

In the `strings` dictionary in `LocalizationService.swift`, add:

```swift
        "widget_pro_title": ["tr": "SpeedLab Pro", "en": "SpeedLab Pro"],
        "widget_pro_sub": ["tr": "Hız sonuçlarını ana ekranında gör", "en": "See your speeds on the Home Screen"],
        "widget_empty": ["tr": "İlk testini çalıştır", "en": "Run your first test"],
        "widget_recent": ["tr": "Son testler", "en": "Recent"],
```

- [ ] **Step 2: Verify it compiles**

Run: `cd ~/SpeedLab && xcodebuild build -project SpeedLab.xcodeproj -scheme SpeedLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add SpeedLab/Services/LocalizationService.swift
git commit -m "feat: localization strings for the widget"
```

---

### Task 4: Widget extension target + minimal building widget

**Files:**
- Modify: `project.yml`
- Create: `SpeedLabWidget/SpeedLabWidget.entitlements`
- Create: `SpeedLabWidget/SpeedLabWidget.swift`

- [ ] **Step 1: Add the widget target + URL scheme + embed to `project.yml`**

Under `targets.SpeedLab`, add the URL scheme to the `info.properties` block (alongside the existing keys):

```yaml
        CFBundleURLTypes:
          - CFBundleURLSchemes:
              - speedlab
```

Add the widget as an embedded dependency of the app — change the app's `dependencies:` to:

```yaml
    dependencies:
      - package: GoogleMobileAds
      - target: SpeedLabWidget
        embed: true
```

Add the new widget target (sibling of `SpeedLab` under `targets:`):

```yaml
  SpeedLabWidget:
    type: app-extension
    platform: iOS
    sources:
      - SpeedLabWidget
      - path: SpeedLab/WidgetShared
      - path: SpeedLab/Extensions/Color+Theme.swift
      - path: SpeedLab/Services/LocalizationService.swift
      - path: SpeedLab/Views/ShareCard/ShareGaugeView.swift
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.vialab.speedlab.widget
        CODE_SIGN_ENTITLEMENTS: SpeedLabWidget/SpeedLabWidget.entitlements
        TARGETED_DEVICE_FAMILY: "1"
    info:
      path: SpeedLabWidget/Info.plist
      properties:
        CFBundleDisplayName: SpeedLab
        NSExtension:
          NSExtensionPointIdentifier: com.apple.widgetkit-extension
```

- [ ] **Step 2: Create the widget entitlements**

```xml
<!-- SpeedLabWidget/SpeedLabWidget.entitlements -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.com.vialab.speedlab</string>
	</array>
</dict>
</plist>
```

- [ ] **Step 3: Create a minimal building widget**

```swift
// SpeedLabWidget/SpeedLabWidget.swift
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
        Text("SpeedLab")
            .containerBackground(Color.npBackground, for: .widget)
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
```

- [ ] **Step 4: Regenerate and build the widget target**

Run: `cd ~/SpeedLab && xcodegen generate && xcodebuild build -project SpeedLab.xcodeproj -scheme SpeedLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO 2>&1 | tail -4`
Expected: `** BUILD SUCCEEDED **` (builds app + embedded widget extension).

- [ ] **Step 5: Run the existing test suite (no regressions)**

Run: `xcodebuild test -project SpeedLab.xcodeproj -scheme SpeedLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "Executed [0-9]+ test|TEST SUCCEEDED|TEST FAILED" | tail -2`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add project.yml SpeedLabWidget SpeedLab.xcodeproj
git commit -m "feat: add SpeedLabWidget extension target (App Group, URL scheme, embed)"
```

---

### Task 5: Widget content (families + Pro/upsell/empty)

Replace the placeholder `SpeedLabWidgetEntryView` with the real content. The whole view is wrapped in a `widgetURL` so taps route correctly.

**Files:**
- Modify: `SpeedLabWidget/SpeedLabWidget.swift`

- [ ] **Step 1: Replace `SpeedLabWidgetEntryView` with the full implementation**

```swift
struct SpeedLabWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: SpeedEntry
    private let loc = LocalizationService.shared

    var body: some View {
        content
            .containerBackground(Color.npBackground, for: .widget)
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
```

- [ ] **Step 2: Build the widget**

Run: `cd ~/SpeedLab && xcodebuild build -project SpeedLab.xcodeproj -scheme SpeedLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add SpeedLabWidget/SpeedLabWidget.swift
git commit -m "feat: widget content for small/medium/large + Pro upsell + empty states"
```

---

### Task 6: Handle the widget tap (open paywall)

**Files:**
- Modify: `SpeedLab/App/SpeedLabApp.swift`

- [ ] **Step 1: Present the paywall on `speedlab://pro`**

In `SpeedLabApp.swift`, add a state property to the `App` struct:

```swift
    @State private var showWidgetPaywall = false
```

Attach `.onOpenURL` and a `.sheet` to the `Group { ... }` block (after `.onChange(of: scenePhase)`):

```swift
            .onOpenURL { url in
                if url.host == "pro" { showWidgetPaywall = true }
            }
            .sheet(isPresented: $showWidgetPaywall) {
                ProUpgradeSheet().environmentObject(storeVM)
            }
```

- [ ] **Step 2: Build to verify it compiles**

Run: `cd ~/SpeedLab && xcodebuild build -project SpeedLab.xcodeproj -scheme SpeedLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add SpeedLab/App/SpeedLabApp.swift
git commit -m "feat: open Pro paywall from widget tap (speedlab://pro)"
```

---

### Task 7: Visual verification + manual check (no App Store build)

**Files:** none (verification only)

- [ ] **Step 1: Render the widget views to PNG for inspection**

Create a temporary test `SpeedLabTests/_ExportWidget.swift` that renders each family/state via `ImageRenderer` at the widget point sizes (small 158×158, medium 338×158, large 338×354) and writes PNGs to `NSTemporaryDirectory()`, printing each path with prefix `EXPORTED::`. Render: upsell (small), Pro small, Pro medium, Pro large, empty (small). Run only that test, copy the PNGs from the simulator data container to `/tmp`, and open them. Confirm: gauge filled (large), no clipping, upsell shows crown, localization (TR/EN). Then delete `_ExportWidget.swift` and `xcodegen generate`.

- [ ] **Step 2: Manual check in the simulator**

Build/run the app; add the SpeedLab widget (small/medium/large) to the home screen. Run a test → widget updates within seconds. With `isPro=false`, the widget shows the upsell; tap it → app opens the paywall. (Toggle Pro via the app's purchase flow / StoreKit config to verify both states.)

- [ ] **Step 3: Confirm no App Store build was produced**

Do not run `archive` / `altool --upload-app`. Ships in a later build after v1.0.2 (build 6) review resolves.

---

## Self-Review

**Spec coverage:** small/medium/large families (Task 5) ✓; Pro-gated with upsell (Task 5 `upsell`, isPro from store) ✓; tap → `speedlab://pro` paywall (Task 5 widgetURL + Task 6 onOpenURL) ✓; App Group + shared store (Task 1) ✓; app writes snapshot + isPro + reload (Task 2) ✓; large reuses `ShareGaugeView` (Task 4 sources + Task 5 large) ✓; empty state (Task 5 `empty`) ✓; TR/EN localization (Task 3) ✓; SharedStore unit tests (Task 1) ✓; visual render verification (Task 7) ✓; no App Store build (Task 7) ✓.

**Placeholders:** none — full code in each code step; commands have expected output. (Task 7 Step 1 describes a throwaway export harness rather than committed code — intentional, mirrors the share-card verification.)

**Type consistency:** `WidgetSnapshot(download:upload:ping:jitter:isp:date:)`, `SharedStore` (`save`, `loadSnapshot`, `setPro`, `isPro`, `saveRecent`, `recentDownloads`, `init(defaults:)`), `AppGroup.id`, `SpeedEntry(date:snapshot:isPro:recent:)`, `ShareGaugeView(value:speed:diameter:)` are consistent across tasks. Theme tokens (`npBackground, npCyan, npPurple, npGreen, npOrange, npTextSecondary, LinearGradient.npMain`) exist. `loc.language == .tr` matches `AppLanguage`. The app's `storeVM`/`ProUpgradeSheet` exist (Task 6).
