# Pro Home-Screen Widget — Design

**Date:** 2026-05-24
**Status:** Approved (design)
**Feature:** A WidgetKit home-screen widget showing the user's last speed test result. Advertised Pro feature → Pro-gated with an upsell state for free users.

## Goal

Deliver the "Home screen widget" Pro perk that the paywall already advertises. The widget shows the latest speed test at a glance and drives Pro conversion (upsell for free users).

## Decisions (locked)

- **Families:** systemSmall, systemMedium, systemLarge.
- **Pro-gated:** widget reads an `isPro` flag from the shared store. Pro → result content; free → "👑 SpeedLab Pro" upsell.
- **Tap:** `widgetURL`. Free/upsell → `speedlab://pro` (app opens the Pro paywall). Pro content → opens the app.
- **Theme:** app dark theme (reuse `Color+Theme.swift`).
- **Localization:** TR/EN via `LocalizationService` (shared into the widget target).
- **Empty state** (no test yet): "Run your first test" prompt.

## Architecture (Approach A — WidgetKit extension + App Group)

- **App Group:** `group.com.vialab.speedlab`, entitlement added to BOTH the app and the widget target.
- **`SpeedLab/WidgetShared/` (compiled into both targets):**
  - `WidgetSnapshot.swift` — `Codable` struct: `download, upload, ping, jitter` (Double), `isp` (String), `date` (Date).
  - `SharedStore.swift` — reads/writes the latest `WidgetSnapshot` (JSON) + `isPro` (Bool) to `UserDefaults(suiteName: "group.com.vialab.speedlab")`. Pure, testable.
  - `Color+Theme.swift`, `LocalizationService.swift`, and `ShareGaugeView.swift` (for the Large gauge) are added to the widget target's sources too (already exist; just include). `ShareGaugeView` is animation-free, so it renders correctly inside a widget.
- **New target `SpeedLabWidget`** (type `app-extension`, WidgetKit, iOS 16+, bundle id `com.vialab.speedlab.widget`, embedded in the app):
  - `Provider: TimelineProvider` — one entry from `SharedStore`; timeline policy `.never` (app reloads on demand).
  - `SpeedLabWidgetEntryView` — switches on `@Environment(\.widgetFamily)` and `isPro` → content vs upsell vs empty.
  - `@main SpeedLabWidget: Widget` (StaticConfiguration), `.supportedFamilies([.systemSmall, .systemMedium, .systemLarge])`.

## Data flow

- App **writes** on every saved test: `SharedStore.save(snapshot:)` from `HistoryService.save(_:)` (or the VM that calls it), then `WidgetCenter.shared.reloadAllTimelines()`.
- App **writes `isPro`**: `StoreViewModel` writes `SharedStore.setPro(_:)` whenever entitlement is (re)checked, then reloads timelines.
- Widget **reads** snapshot + isPro from `SharedStore` in `Provider`.

## Widget content

- **Small:** download number + "Mbps ↓", small upload/ping line, relative time ("2 dk önce").
- **Medium:** brand + relative time; row of download/upload/ping/jitter; ISP.
- **Large:** brand + a compact static gauge (reuse `ShareGaugeView` with a small `diameter`) + metrics + a "recent" row of the last 3 downloads.
- **Free (any family):** crown + "SpeedLab Pro" + one-line value prop; whole widget is a `speedlab://pro` link.
- **Empty:** prompt to run the first test.

## Tap behavior

- Register URL scheme `speedlab` in the app Info.plist (`CFBundleURLTypes`).
- App handles `.onOpenURL`: `speedlab://pro` → present the Pro paywall sheet (`ProUpgradeSheet`). Other URLs → no-op (app just opens).

## Testing

- **Unit (testable):** `SharedStore` round-trip (save → load snapshot equals input; setPro/getPro); `WidgetSnapshot` Codable. Run against a temporary `UserDefaults(suiteName:)`.
- **Visual:** SwiftUI Previews for each family × (Pro / upsell / empty); render the entry views to PNG (as done for the share card) for inspection.
- **Manual:** add each widget size in the simulator; run a test → widget updates; toggle isPro → upsell appears/disappears; tap upsell → paywall opens.

## Constraints

- **No new App Store build while v1.0.2 (build 6) is in review.** Build + simulator test + commit only; ship in a later build.
- App Group + widget extension require provisioning updates (App Group capability, widget app ID) in the Apple Developer portal before an App Store build — not needed for local/simulator runs.

## Out of scope (separate specs)

A1 WiFi coverage map, A3 CSV/PDF export. Each its own design → plan → implementation cycle.
