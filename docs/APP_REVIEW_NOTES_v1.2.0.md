# App Review Notes — SpeedLab 1.2.0 (build 12)

Demo account: not required (no login).

## What changed
- New main screen: cockpit-style gauge (Canvas), live download/upload graph, result cards with usage context.
- History: day/week/month chart (Charts framework), connection/carrier filters, swipe to delete.
- Export (Pro only): History tab → "Export" → CSV (all records) or PDF (selected range). Uses the standard share sheet.
- WiFi tab: shows a normalized "signal quality" value from `NEHotspotNetwork.fetchCurrent()` (0–1). No dBm, band or channel is shown; those rows read "not shared by iOS". Location permission is requested only to read the SSID (existing behavior, same usage string).
- Light appearance (Settings → Appearance: System / Dark / Light).
- New app icon.

## Monetization
- Same two auto-renewable subscriptions (`com.vialab.speedlab.pro.monthly`, `com.vialab.speedlab.pro.yearly`), SubscriptionStoreView with Terms (EULA) and Privacy links.
- Pro benefits listed in-app: ad-free, unlimited history + charts, CSV/PDF export, widget. The previous "WiFi signal map" claim was removed because that feature does not exist.
- Ads (Google Mobile Ads): banner above the tab bar; interstitial only after a completed test and after the result cards finish animating. The former rewarded-ad button was removed.

## How to reach features quickly
1. Speed Test tab → tap the gauge → wait ~15 s → result cards slide in.
2. History tab → "Day/Week/Month" picker; free users see the last 3 tests on the chart and the Pro sheet when choosing Week/Month.
3. History tab → "Export" (Pro) → CSV / PDF.
4. Settings → Appearance → Light.
