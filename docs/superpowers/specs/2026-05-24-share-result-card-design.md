# Shareable Result Card — Design

**Date:** 2026-05-24
**Status:** Approved (design)
**Feature:** Turn the plain-text "Share" action into a rendered, branded image card for social sharing (organic growth).

## Goal

When a user finishes a speed test, let them share a polished image card (instead of the current plain text). The card carries SpeedLab branding + a QR code to the App Store to drive organic installs.

## Decisions (locked)

- **Formats:** both **square (1080×1080)** and **story (1080×1920)**; user picks at share time.
- **Hierarchy:** **hero download speed** (large), with upload / ping / jitter secondary.
- **Branding:** SpeedLab logo + "Sen de ölç / Test yours" CTA + **QR code** to the App Store
  (`https://apps.apple.com/app/id6761667861`).
- **Theme:** app dark theme (`Color.npBackground`, cyan/gauge accents from `Color+Theme.swift`).
- **Localization:** TR/EN via existing `LocalizationService`.
- Data source: existing `vm.lastResult` (`SpeedTestResult`). No new persisted state.

## Architecture

One parameterized SwiftUI card rendered to a bitmap via `ImageRenderer` (iOS 16+, no third-party deps).

New / changed files:

- `SpeedLab/Views/ShareCard/ShareCardView.swift` — the card UI. Inputs: `result: SpeedTestResult`,
  `format: ShareCardFormat` (`.square` / `.story`), reads `LocalizationService`. Pure view, no side effects.
- `SpeedLab/Services/ShareCardRenderer.swift` — `@MainActor` helper. Wraps `ShareCardView` in `ImageRenderer`,
  sets `proposedSize` + `scale` so output is exactly 1080×1080 or 1080×1920, returns `UIImage?`.
- `SpeedLab/Services/QRCodeGenerator.swift` — small util: `CIQRCodeGenerator` → `UIImage` for a given URL string
  (high error-correction, tinted to match theme, nil-safe).
- `SpeedLab/Views/SpeedTestView.swift` — replace the text-only `shareResult()`:
  1. present a small dialog (Kare / Story),
  2. render the chosen format to `UIImage`,
  3. share via `UIActivityViewController` with `[image, caption]` where caption is a short localized string
     + hashtag + App Store link (text accompanies the image; some targets strip one or the other).

`ShareCardFormat` enum lives with `ShareCardView` and exposes its pixel size.

## Card content & layout

Both formats show the same data; spacing/placement differ.

```
SQUARE (1:1, 1080×1080)              STORY (9:16, 1080×1920)
┌───────────────────────┐           ┌─────────────────┐
│ 🌀 SpeedLab            │           │   🌀 SpeedLab    │
│                        │           │                 │
│       38.2             │           │      38.2       │
│       Mbps  ↓ Download │           │    Mbps ↓       │
│                        │           │    Download     │
│  ↑ 12.4   📡 14   ~ 2  │           │                 │
│  Upload   Ping  Jitter │           │ ↑12.4 📡14 ~2   │
│                        │           │                 │
│ Turknet · 24 May   ▣QR │           │   Turknet       │
│ Sen de ölç →           │           │   24 May 2026   │
└───────────────────────┘           │                 │
                                     │      ▣ QR       │
                                     │   Sen de ölç →  │
                                     └─────────────────┘
```

- Hero: `downloadSpeed` formatted `%.1f` + unit "Mbps" + "↓ Download" label.
- Secondary row: `uploadSpeed` (↑), `ping` (📡, `%.0f` ms), `jitter` (~, `%.0f` ms).
- Footer: `isp` · localized short date; CTA "Sen de ölç →" + QR.
- Square: QR small, bottom-right. Story: QR + CTA centered near bottom with more vertical breathing room.

## Flow

1. User taps existing **Share** button on results.
2. Confirmation dialog: **Kare** / **Story** (+ Cancel).
3. `ShareCardRenderer` rasterizes the selected format.
4. `UIActivityViewController` presents with `[UIImage, captionText]`.

Caption (localized), e.g. EN: `"Measured 38.2 Mbps ↓ with SpeedLab #speedtest <App Store link>"`.

## Edge cases

- Empty `isp` / `ssid` → that footer line is hidden (no "-").
- `ImageRenderer` returns nil → fall back to the current text-only share (no crash, no dead button).
- iPad popover: set `UIActivityViewController` `popoverPresentationController.sourceView/sourceRect` (reuse existing share-presentation code path).
- QR uses the fixed App Store URL; link is live only after the app is approved (acceptable — feature ships in a post-approval build).

## Testing

- `ShareCardView` SwiftUI Previews for both formats with sample `SpeedTestResult` (TR + EN).
- Unit/smoke: `ShareCardRenderer` returns non-nil `UIImage` with expected pixel dimensions for each format; `QRCodeGenerator` returns non-nil image for a valid URL.
- Manual: run app → complete a test → Share → render both formats → confirm QR scans to the App Store page.

## Constraints

- **No new App Store build while v1.0.2 (build 6) is in review.** Implement, local compile-check, commit only.
  Ship in a later build after the current review resolves.

## Out of scope (separate specs later)

WiFi coverage map (A1), Home-screen Widget (A2), CSV/PDF export (A3), History charts (C). Each gets its own design → plan → implementation cycle.
