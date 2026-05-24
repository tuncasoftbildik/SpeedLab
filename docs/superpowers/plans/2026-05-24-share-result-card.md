# Shareable Result Card Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace SpeedLab's plain-text result share with a branded image card (signature speed gauge + QR to the App Store), in square (1080×1080) and story (1080×1920) formats.

**Architecture:** One parameterized SwiftUI `ShareCardView` rasterized via `ImageRenderer` (iOS 16+). A static, animation-free `ShareGaugeView` is the hero (the animated `SpeedGaugeView` renders empty off-screen). QR via CoreImage. The existing `shareResult()` gains a format picker and shares the rendered `UIImage` + a caption. No third-party deps.

**Tech Stack:** SwiftUI, ImageRenderer, CoreImage (`CIQRCodeGenerator`), XCTest, xcodegen.

**Constraint:** Do NOT archive/upload a new App Store build while v1.0.2 (build 6) is in review. Local simulator builds/tests + commits only. This feature ships in a later build.

---

## File Structure

- `project.yml` — add a `SpeedLabTests` unit-test target + attach it to the SpeedLab scheme.
- `SpeedLabTests/` (new) — `SmokeTests.swift`, `ShareCardFormatTests.swift`, `QRCodeGeneratorTests.swift`, `ShareCardRendererTests.swift`.
- `SpeedLab/Views/ShareCard/ShareCardFormat.swift` (new) — `ShareCardFormat` enum (pixel/point sizes, render scale) + `AppStore.url` constant.
- `SpeedLab/Services/QRCodeGenerator.swift` (new) — URL → `UIImage?` QR.
- `SpeedLab/Views/ShareCard/ShareGaugeView.swift` (new) — static gauge.
- `SpeedLab/Views/ShareCard/ShareCardView.swift` (new) — the card UI (both formats).
- `SpeedLab/Services/ShareCardRenderer.swift` (new) — `ShareCardView` → `UIImage`.
- `SpeedLab/Services/LocalizationService.swift` (modify) — add card strings.
- `SpeedLab/Views/SpeedTestView.swift` (modify) — format picker + share image.

---

### Task 1: Add unit-test target

**Files:**
- Modify: `project.yml`
- Create: `SpeedLabTests/SmokeTests.swift`

- [ ] **Step 1: Add the test target to `project.yml`**

Under `targets.SpeedLab`, add a `scheme` block so tests run from the SpeedLab scheme. Then add the test target. Append after the `SpeedLab` target definition:

```yaml
  SpeedLab:
    # ... existing keys unchanged ...
    scheme:
      testTargets:
        - SpeedLabTests

  SpeedLabTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - SpeedLabTests
    dependencies:
      - target: SpeedLab
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
        PRODUCT_BUNDLE_IDENTIFIER: com.vialab.speedlab.tests
        TEST_HOST: "$(BUILT_PRODUCTS_DIR)/SpeedLab.app/SpeedLab"
        BUNDLE_LOADER: "$(TEST_HOST)"
```

(Keep the existing `scheme` for SpeedLab if one already exists — merge `testTargets` into it rather than duplicating.)

- [ ] **Step 2: Create a smoke test**

```swift
// SpeedLabTests/SmokeTests.swift
import XCTest
@testable import SpeedLab

final class SmokeTests: XCTestCase {
    func test_appModuleLoads() {
        XCTAssertEqual(AppLanguage.tr.rawValue, "tr")
    }
}
```

- [ ] **Step 3: Regenerate the project**

Run: `cd ~/SpeedLab && xcodegen generate`
Expected: `Created project at .../SpeedLab.xcodeproj`

- [ ] **Step 4: Run the test (verify the target works)**

Run: `xcodebuild test -project SpeedLab.xcodeproj -scheme SpeedLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add project.yml SpeedLabTests/SmokeTests.swift SpeedLab.xcodeproj
git commit -m "test: add SpeedLabTests unit-test target"
```

---

### Task 2: `ShareCardFormat` + `AppStore.url`

**Files:**
- Create: `SpeedLab/Views/ShareCard/ShareCardFormat.swift`
- Test: `SpeedLabTests/ShareCardFormatTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
// SpeedLabTests/ShareCardFormatTests.swift
import XCTest
@testable import SpeedLab

final class ShareCardFormatTests: XCTestCase {
    func test_pixelSizes() {
        XCTAssertEqual(ShareCardFormat.square.pixelSize, CGSize(width: 1080, height: 1080))
        XCTAssertEqual(ShareCardFormat.story.pixelSize, CGSize(width: 1080, height: 1920))
    }
    func test_pointSizeIsPixelOverScale() {
        XCTAssertEqual(ShareCardFormat.square.pointSize.width,
                       1080 / ShareCardFormat.renderScale, accuracy: 0.01)
    }
    func test_appStoreURL() {
        XCTAssertEqual(AppStore.url, "https://apps.apple.com/app/id6761667861")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project SpeedLab.xcodeproj -scheme SpeedLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SpeedLabTests/ShareCardFormatTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -8`
Expected: build failure — `cannot find 'ShareCardFormat' in scope`.

- [ ] **Step 3: Implement**

```swift
// SpeedLab/Views/ShareCard/ShareCardFormat.swift
import CoreGraphics

enum AppStore {
    static let url = "https://apps.apple.com/app/id6761667861"
}

enum ShareCardFormat: String, CaseIterable, Identifiable {
    case square
    case story

    var id: String { rawValue }

    /// Final rasterized image size in pixels.
    var pixelSize: CGSize {
        switch self {
        case .square: return CGSize(width: 1080, height: 1080)
        case .story:  return CGSize(width: 1080, height: 1920)
        }
    }

    /// SwiftUI layout size in points (rendered at `renderScale`).
    var pointSize: CGSize {
        CGSize(width: pixelSize.width / Self.renderScale,
               height: pixelSize.height / Self.renderScale)
    }

    static let renderScale: CGFloat = 3
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project SpeedLab.xcodeproj -scheme SpeedLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SpeedLabTests/ShareCardFormatTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add SpeedLab/Views/ShareCard/ShareCardFormat.swift SpeedLabTests/ShareCardFormatTests.swift SpeedLab.xcodeproj
git commit -m "feat: ShareCardFormat sizes + App Store URL"
```

---

### Task 3: `QRCodeGenerator`

**Files:**
- Create: `SpeedLab/Services/QRCodeGenerator.swift`
- Test: `SpeedLabTests/QRCodeGeneratorTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
// SpeedLabTests/QRCodeGeneratorTests.swift
import XCTest
@testable import SpeedLab

final class QRCodeGeneratorTests: XCTestCase {
    func test_validURLProducesImage() {
        XCTAssertNotNil(QRCodeGenerator.generate(from: AppStore.url))
    }
    func test_emptyStringReturnsNil() {
        XCTAssertNil(QRCodeGenerator.generate(from: ""))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project SpeedLab.xcodeproj -scheme SpeedLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SpeedLabTests/QRCodeGeneratorTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -8`
Expected: `cannot find 'QRCodeGenerator' in scope`.

- [ ] **Step 3: Implement**

```swift
// SpeedLab/Services/QRCodeGenerator.swift
import UIKit
import CoreImage.CIFilterBuiltins

enum QRCodeGenerator {
    static func generate(from string: String, scale: CGFloat = 12) -> UIImage? {
        guard !string.isEmpty, let data = string.data(using: .utf8) else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project SpeedLab.xcodeproj -scheme SpeedLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SpeedLabTests/QRCodeGeneratorTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add SpeedLab/Services/QRCodeGenerator.swift SpeedLabTests/QRCodeGeneratorTests.swift SpeedLab.xcodeproj
git commit -m "feat: QR code generator for App Store link"
```

---

### Task 4: `ShareGaugeView` (static gauge)

No unit test (pure view); verified via the renderer test in Task 6 + SwiftUI Preview. Mirrors `SpeedGaugeView`'s geometry (arc trim 0.15–0.85, rotation 126°, lineWidth 20, 240pt frame, 13 ticks) but draws the value arc directly (no `@State`, no animation) and color-codes orange→cyan.

**Files:**
- Create: `SpeedLab/Views/ShareCard/ShareGaugeView.swift`

- [ ] **Step 1: Implement the view**

```swift
// SpeedLab/Views/ShareCard/ShareGaugeView.swift
import SwiftUI

struct ShareGaugeView: View {
    let value: Double   // 0...1 normalized speed
    let speed: Double   // Mbps

    private var clamped: Double { min(max(value, 0), 1) }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .trim(from: 0.15, to: 0.85)
                .rotation(.degrees(126))
                .stroke(Color.npSurfaceLight, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .frame(width: 240, height: 240)

            // Value arc (static — drawn directly at `clamped`, orange→cyan)
            Circle()
                .trim(from: 0.15, to: 0.15 + clamped * 0.7)
                .rotation(.degrees(126))
                .stroke(
                    AngularGradient(
                        colors: [.npOrange, .npPrimary, .npCyan],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: 240, height: 240)
                .shadow(color: .npCyan.opacity(0.4), radius: 12)

            // Ticks
            ForEach(0..<13, id: \.self) { i in
                let angle = 126.0 + Double(i) * (252.0 / 12.0)
                Rectangle()
                    .fill(i % 3 == 0 ? Color.npTextSecondary : Color.npSurfaceLight)
                    .frame(width: i % 3 == 0 ? 2 : 1, height: i % 3 == 0 ? 12 : 8)
                    .offset(y: -108)
                    .rotationEffect(.degrees(angle))
            }

            // Center value
            VStack(spacing: 4) {
                Text(speed < 1 ? String(format: "%.1f", speed) : String(format: "%.0f", speed))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient.npMain)
                Text("Mbps ↓")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.npTextSecondary)
            }
        }
        .frame(width: 260, height: 260)
    }
}

#Preview {
    ZStack {
        Color.npBackground
        ShareGaugeView(value: 0.19, speed: 38.2)
    }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `xcodebuild build -project SpeedLab.xcodeproj -scheme SpeedLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add SpeedLab/Views/ShareCard/ShareGaugeView.swift SpeedLab.xcodeproj
git commit -m "feat: static ShareGaugeView for off-screen rendering"
```

---

### Task 5: Localization strings

**Files:**
- Modify: `SpeedLab/Services/LocalizationService.swift`

- [ ] **Step 1: Add card strings to the `strings` dictionary**

Open `LocalizationService.swift`. Inside the `private let strings: [String: [String: String]] = [ ... ]` dictionary, add these entries (anywhere among the existing pairs, same format):

```swift
        "share_cta": ["tr": "Sen de ölç →", "en": "Test yours →"],
        "share_caption": ["tr": "SpeedLab ile ölçtüm", "en": "Measured with SpeedLab"],
        "share_format_title": ["tr": "Kart formatı", "en": "Card format"],
        "share_format_square": ["tr": "Kare", "en": "Square"],
        "share_format_story": ["tr": "Story", "en": "Story"],
```

- [ ] **Step 2: Verify it compiles**

Run: `xcodebuild build -project SpeedLab.xcodeproj -scheme SpeedLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add SpeedLab/Services/LocalizationService.swift
git commit -m "feat: localization strings for share card"
```

---

### Task 6: `ShareCardView` + `ShareCardRenderer`

**Files:**
- Create: `SpeedLab/Views/ShareCard/ShareCardView.swift`
- Create: `SpeedLab/Services/ShareCardRenderer.swift`
- Test: `SpeedLabTests/ShareCardRendererTests.swift`

- [ ] **Step 1: Implement `ShareCardView`**

```swift
// SpeedLab/Views/ShareCard/ShareCardView.swift
import SwiftUI

struct ShareCardView: View {
    let result: SpeedTestResult
    let format: ShareCardFormat

    private let loc = LocalizationService.shared

    private var normalized: Double { min(result.downloadSpeed / 200.0, 1.0) }

    private var dateText: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = Locale(identifier: loc.language == .tr ? "tr_TR" : "en_US")
        return f.string(from: result.date)
    }

    var body: some View {
        VStack(spacing: format == .story ? 44 : 26) {
            // Brand
            HStack(spacing: 8) {
                Image(systemName: "gauge.high")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(LinearGradient.npMain)
                Text("SpeedLab")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }

            ShareGaugeView(value: normalized, speed: result.downloadSpeed)

            // Secondary metrics
            HStack(spacing: 28) {
                metric(symbol: "arrow.up", value: String(format: "%.1f", result.uploadSpeed), label: loc.t("upload"), color: .npPurple)
                metric(symbol: "dot.radiowaves.left.and.right", value: String(format: "%.0f", result.ping), label: loc.t("ping"), color: .npCyan)
                metric(symbol: "waveform.path", value: String(format: "%.0f", result.jitter), label: loc.t("jitter"), color: .npOrange)
            }

            // Footer: ISP · date
            if !result.isp.isEmpty {
                Text("\(result.isp) · \(dateText)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.npTextSecondary)
            } else {
                Text(dateText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.npTextSecondary)
            }

            // CTA + QR
            HStack(spacing: 14) {
                if let qr = QRCodeGenerator.generate(from: AppStore.url) {
                    Image(uiImage: qr)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 76, height: 76)
                        .padding(6)
                        .background(Color.white)
                        .cornerRadius(10)
                }
                Text(loc.t("share_cta"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.npCyan)
            }
            .padding(.top, format == .story ? 8 : 0)
        }
        .padding(format == .story ? 48 : 36)
        .frame(width: format.pointSize.width, height: format.pointSize.height)
        .background(Color.npBackground)
    }

    private func metric(symbol: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.npTextSecondary)
        }
    }
}

#Preview {
    ShareCardView(
        result: SpeedTestResult(downloadSpeed: 38.2, uploadSpeed: 12.4, ping: 14, jitter: 2, ssid: "Home", isp: "Turknet", ipAddress: "1.2.3.4"),
        format: .square
    )
}
```

- [ ] **Step 2: Implement `ShareCardRenderer`**

```swift
// SpeedLab/Services/ShareCardRenderer.swift
import SwiftUI
import UIKit

@MainActor
enum ShareCardRenderer {
    static func render(result: SpeedTestResult, format: ShareCardFormat) -> UIImage? {
        let view = ShareCardView(result: result, format: format)
        let renderer = ImageRenderer(content: view)
        renderer.scale = ShareCardFormat.renderScale
        renderer.isOpaque = true
        return renderer.uiImage
    }
}
```

- [ ] **Step 3: Write the renderer test (incl. the critical "not blank" check)**

```swift
// SpeedLabTests/ShareCardRendererTests.swift
import XCTest
import UIKit
@testable import SpeedLab

@MainActor
final class ShareCardRendererTests: XCTestCase {
    private func sampleResult() -> SpeedTestResult {
        SpeedTestResult(downloadSpeed: 38.2, uploadSpeed: 12.4, ping: 14, jitter: 2,
                        ssid: "Home", isp: "Turknet", ipAddress: "1.2.3.4")
    }

    func test_rendersNonNilAtCorrectPixelSize() {
        for format in ShareCardFormat.allCases {
            let img = ShareCardRenderer.render(result: sampleResult(), format: format)
            let img2 = try XCTUnwrap(img, "render returned nil for \(format)")
            XCTAssertEqual(img2.size.width * img2.scale, format.pixelSize.width, accuracy: 1)
            XCTAssertEqual(img2.size.height * img2.scale, format.pixelSize.height, accuracy: 1)
        }
    }

    func test_cardIsNotBlank() throws {
        // Catches the empty-gauge / blank-render failure mode.
        let img = try XCTUnwrap(ShareCardRenderer.render(result: sampleResult(), format: .square))
        let cg = try XCTUnwrap(img.cgImage)
        let w = cg.width, h = cg.height
        var pixels = [UInt32](repeating: 0, count: w * h)
        let cs = CGColorSpaceCreateDeviceRGB()
        let ctx = try XCTUnwrap(CGContext(data: &pixels, width: w, height: h, bitsPerComponent: 8,
                                          bytesPerRow: w * 4, space: cs,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        var colors = Set<UInt32>()
        let stepX = max(1, w / 20), stepY = max(1, h / 20)
        for y in stride(from: 0, to: h, by: stepY) {
            for x in stride(from: 0, to: w, by: stepX) {
                colors.insert(pixels[y * w + x])
            }
        }
        XCTAssertGreaterThan(colors.count, 3, "card looks blank — gauge/content not rendered")
    }
}
```

- [ ] **Step 4: Run the renderer tests**

Run: `xcodebuild test -project SpeedLab.xcodeproj -scheme SpeedLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SpeedLabTests/ShareCardRendererTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -6`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add SpeedLab/Views/ShareCard/ShareCardView.swift SpeedLab/Services/ShareCardRenderer.swift SpeedLabTests/ShareCardRendererTests.swift SpeedLab.xcodeproj
git commit -m "feat: ShareCardView + renderer (square/story)"
```

---

### Task 7: Wire into `SpeedTestView`

Replace the text-only `shareResult()` with a format picker that renders + shares the image (image first, caption second).

**Files:**
- Modify: `SpeedLab/Views/SpeedTestView.swift`

- [ ] **Step 1: Add state for the format dialog**

Near the top of `SpeedTestView` (with the other `@State`/`@StateObject` properties), add:

```swift
    @State private var showShareFormatDialog = false
```

- [ ] **Step 2: Change the Share button to open the dialog and attach the dialog**

Find the Share button's action (currently `shareResult()`) and change it to:

```swift
                            showShareFormatDialog = true
```

Then attach a confirmation dialog to the same view (e.g., right after the `.sheet`/closing of the main `ZStack`/`ScrollView`):

```swift
        .confirmationDialog(loc.t("share_format_title"), isPresented: $showShareFormatDialog, titleVisibility: .visible) {
            Button(loc.t("share_format_square")) { presentShare(format: .square) }
            Button(loc.t("share_format_story")) { presentShare(format: .story) }
            Button("İptal / Cancel", role: .cancel) {}
        }
```

- [ ] **Step 3: Replace `shareResult()` with `presentShare(format:)`**

Replace the entire existing `private func shareResult()` with:

```swift
    @MainActor
    private func presentShare(format: ShareCardFormat) {
        guard let result = vm.lastResult else { return }

        let caption = """
        \(loc.t("share_caption")): \(String(format: "%.1f", result.downloadSpeed)) Mbps ↓
        \(AppStore.url)
        """

        var items: [Any] = [caption]
        if let image = ShareCardRenderer.render(result: result, format: format) {
            items.insert(image, at: 0)
        }

        let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        // iPad popover anchor
        av.popoverPresentationController?.sourceView = root.view
        av.popoverPresentationController?.sourceRect = CGRect(x: root.view.bounds.midX,
                                                              y: root.view.bounds.midY,
                                                              width: 0, height: 0)
        av.popoverPresentationController?.permittedArrowDirections = []
        root.present(av, animated: true)
    }
```

(If the old `shareResult()` referenced `vm.lastResult`/`UIApplication` differently, keep whichever root-VC lookup the file already used — the key change is sharing `[image, caption]` instead of plain text. If a fallback is desired, the existing text path remains valid because `items` still includes the caption when the image is nil.)

- [ ] **Step 4: Build and verify it compiles**

Run: `xcodebuild build -project SpeedLab.xcodeproj -scheme SpeedLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Run the full test suite**

Run: `xcodebuild test -project SpeedLab.xcodeproj -scheme SpeedLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO 2>&1 | tail -6`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add SpeedLab/Views/SpeedTestView.swift SpeedLab.xcodeproj
git commit -m "feat: share rendered result card with format picker"
```

---

### Task 8: Manual verification (no App Store build)

**Files:** none (verification only)

- [ ] **Step 1: Run the app in the simulator**

Run: `xcodebuild build -project SpeedLab.xcodeproj -scheme SpeedLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO` then launch via Xcode/simulator (or `xcrun simctl`).

- [ ] **Step 2: Verify behavior**

- Complete a speed test → tap **Share** → pick **Kare** and **Story**.
- Confirm the share sheet shows a real card image (gauge **filled**, download number centered, upload/ping/jitter, ISP·date, CTA, QR).
- Save the image; scan the QR with the Camera app → resolves to `https://apps.apple.com/app/id6761667861`.
- Toggle app language TR/EN → labels (`upload`/`ping`/`jitter`/CTA) localize.

- [ ] **Step 3: Confirm no App Store build was made**

This feature ships in a future build, after v1.0.2 (build 6) review resolves. Do not run `archive` / `altool --upload-app`.

---

## Self-Review

**Spec coverage:** both formats (Task 2/5/6) ✓; hero static gauge color-coded (Task 4) ✓; secondary metrics + footer ISP·date (Task 6) ✓; branding + CTA + QR to App Store (Task 3/6) ✓; share image + caption, format picker (Task 7) ✓; empty-ISP edge case (Task 6 `if !result.isp.isEmpty`) ✓; nil-render fallback to caption-only (Task 7 `items` still has caption) ✓; TR/EN localization (Task 5/6) ✓; "gauge filled, not blank" critical test (Task 6 `test_cardIsNotBlank`) ✓; no App Store build (Task 8) ✓.

**Placeholders:** none — every code step has complete code; commands have expected output.

**Type consistency:** `ShareCardFormat` (`.square`/`.story`, `pixelSize`, `pointSize`, `renderScale`), `AppStore.url`, `QRCodeGenerator.generate(from:)`, `ShareGaugeView(value:speed:)`, `ShareCardView(result:format:)`, `ShareCardRenderer.render(result:format:)` are used consistently across tasks. `SpeedTestResult` initializer matches the model (`downloadSpeed, uploadSpeed, ping, jitter, ssid, isp, ipAddress`). Theme tokens (`npBackground, npCyan, npOrange, npPurple, npPrimary, npSurfaceLight, npTextSecondary, LinearGradient.npMain`) all exist in the app.
