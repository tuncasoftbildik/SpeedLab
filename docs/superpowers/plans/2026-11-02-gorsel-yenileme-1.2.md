# SpeedLab 1.2.0 Görsel Yenileme — Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** SpeedLab iOS'u 1.2.0'a taşımak: A taslağına göre kokpit kadranlı ana ekran, canlı akış grafiği, bağlamlı sonuçlar, grafikli geçmiş, CSV/PDF dışa aktarma (Pro), dürüst WiFi sekmesi, açık tema, yeni ikon (2 numara) ve yenilenmiş mağaza görselleri.

**Architecture:** Mevcut SwiftUI + ObservableObject mimarisi korunur. Kadran ve canlı grafik `Canvas` ile çizilir (`TimelineView` yalnız boştaki nefes efekti için); geçmiş grafiği Apple `Charts`. Saf mantık (log skala, bağlam bantları, filtre/medyan, CSV üretimi, sinyal kalitesi) görünümlerden ayrı küçük tiplerde yaşar ve XCTest ile doğrulanır; görünümler simülatör ekran görüntüsüyle doğrulanır.

**Tech Stack:** Swift 5.9, SwiftUI, Charts (iOS 16), PDFKit/UIGraphicsPDFRenderer, StoreKit 2, Google Mobile Ads 11.13, XcodeGen, XCTest, tek simülatör: "ViaBus iPhone 18 Pro".

**Spec:** `docs/superpowers/specs/2026-11-02-gorsel-yenileme-1.2-design.md` (taslaklar: aynı klasörde `2026-11-02-kadran-taslak.html/.png`, `2026-11-02-ikon-taslak.html`)

## Global Constraints

- iOS hedefi `16.0` korunur; iOS 17+ API yalnız `#available` ile.
- `project.yml`: `MARKETING_VERSION: "1.2.0"`, `CURRENT_PROJECT_VERSION: 12`. Yeni Swift dosyaları klasör tabanlı hedeflere otomatik girer; `xcodegen generate` her yeni dosyadan sonra çalıştırılır.
- Her yeni kullanıcı metni `LocalizationService.strings` sözlüğüne `"anahtar": ["tr": …, "en": …]` olarak girer; görünümde `loc.t("anahtar")`.
- `SpeedTestResult` Codable şeması geriye uyumlu: yeni alanlar opsiyonel, eski 1.1.2 JSON'u decode edilir.
- Widget hedefi (`SpeedLabWidget`) yalnız `Color.npBrand*` kullanır; `np*` semantik renkler widget hedefine girmez.
- Reklam yerleşimi: banner yalnız tab çubuğunun üstünde; interstitial kartlar oturduktan 1,5 sn sonra; ödüllü reklam kodu kaldırılır.
- Renkler: `npGradientStart #6366F1 → npGradientMid #3B82F6 → npGradientEnd #06B6D4`; açık tema zemin `#F4F6FB`, metin `#0B1020`, ikincil `#5B6478`.
- Kullanım bantları (spec "Bağlam satırları"): indirme <5 / 5–25 / 25–50 / 50–100 / 100+; yükleme <3 / 3–10 / 10+; ping <30 / 30–80 / 80+.
- Ücretsiz: grafik son 3 test, liste son 10 (`HistoryService.maxFreeResults`), dışa aktarma ve Hafta/Ay aralığı Pro.
- Test komutu (her görevde aynı):
  `cd ~/SpeedLab && xcodegen generate -q && xcodebuild test -project SpeedLab.xcodeproj -scheme SpeedLab -destination 'platform=iOS Simulator,name=ViaBus iPhone 18 Pro' -only-testing:SpeedLabTests/<Sınıf> 2>&1 | grep -E "Test Case|error:|\*\* TEST" | tail -20`
- Görsel doğrulama komutu: uygulamayı simülatöre kur, çalıştır, `xcrun simctl io "ViaBus iPhone 18 Pro" screenshot <yol>.png`, görüntüyü oku ve taslakla karşılaştır. Her görünüm görevi TR + EN ve koyu + açık dört görüntü alır.
- Commit mesajları Türkçe, `feat:/fix:/chore:` önekli, sonda `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.

## Review Focus

1. **Eski geçmiş verisi**: 1.1.2'den gelen `ssid`, `isp`, `ipAddress` dolu ama yeni alanlar yok → decode başarılı, `effectiveConnectionType` SSID'den türetilir (Task 2 testi).
2. **Boş veya tek kayıtlı geçmiş**: grafik ve medyan 0 veya 1 kayıtla çökmemeli; bağlam satırı "ortalamada" yerine gizlenir (Task 3 ve Task 7 testleri).
3. **1 Gbps üstü ve sıfır hız**: log skala 0'da 0, 1000+'da 1'e doyar, NaN üretmez (Task 3 testi).
4. **Sinyal değeri 0 (iOS vermiyor)**: WiFi kadranı "Ölçülemiyor", grafik gizli; sahte yüzde yok (Task 9 testi).
5. **Pro olmayan kullanıcı dışa aktarmaya basınca**: dosya üretilmez, Pro sayfası açılır; Pro'da 0 kayıtla CSV yalnız başlık satırı, PDF yine üretilir (Task 8 testi).

---

### Task 1: Sürüm, tema altyapısı ve görünüm tercihi

**Files:**
- Modify: `project.yml:12-13`
- Modify: `SpeedLab/Extensions/Color+Theme.swift`
- Create: `SpeedLab/Services/AppearanceSetting.swift`
- Modify: `SpeedLab/App/SpeedLabApp.swift:28`
- Modify: `SpeedLab/Views/SettingsView.swift` (Dil bölümünün altına "Görünüm")
- Modify: `SpeedLab/Services/LocalizationService.swift` (anahtarlar: `appearance`, `appearance_system`, `appearance_dark`, `appearance_light`)
- Test: `SpeedLabTests/AppearanceSettingTests.swift`

**Interfaces:**
- Produces: `enum AppearanceSetting: String, CaseIterable { case system, dark, light; var colorScheme: ColorScheme? }` ve `static let storageKey = "appearance"`.
- Produces: `Color.npBrandBackground/npBrandSurface/npBrandSurfaceLight/npBrandTextSecondary` (sabit koyu, eski hex değerleri) ve semantik `npBackground/npSurface/npSurfaceLight/npTextPrimary/npTextSecondary/npBorder` (trait'e göre çözen `Color(uiColor: UIColor { … })`). Vurgular (`npPrimary, npBlue, npCyan, npGreen, npOrange, npRed, npPurple`) ve gradyanlar aynen kalır.

- [ ] **Step 1: Failing test**

```swift
import XCTest
import SwiftUI
@testable import SpeedLab

final class AppearanceSettingTests: XCTestCase {
    func test_colorSchemeMapping() {
        XCTAssertNil(AppearanceSetting.system.colorScheme)
        XCTAssertEqual(AppearanceSetting.dark.colorScheme, .dark)
        XCTAssertEqual(AppearanceSetting.light.colorScheme, .light)
    }
    func test_defaultIsSystem() {
        XCTAssertEqual(AppearanceSetting(rawValue: "") ?? .system, .system)
        XCTAssertEqual(AppearanceSetting.storageKey, "appearance")
    }
}
```

- [ ] **Step 2: Çalıştır, "cannot find 'AppearanceSetting'" ile FAIL gör**
- [ ] **Step 3: `AppearanceSetting.swift` yaz** (enum + `colorScheme` + `storageKey`).
- [ ] **Step 4: `Color+Theme.swift`'i böl**: `npBrand*` statikleri eski hex'lerle; semantik `np*` için `UIColor { trait in trait.userInterfaceStyle == .dark ? koyu : açık }`; açık değerler: zemin `#F4F6FB`, yüzey `#FFFFFF` %70, yüzeyAçık `#E9EDF7`, metin `#0B1020`, ikincil `#5B6478`, kenar `#D6DBEA`. `npTextPrimary` artık `.white` değil semantik.
- [ ] **Step 5: `SpeedLabApp.swift`**: `@AppStorage(AppearanceSetting.storageKey) private var appearance = AppearanceSetting.system.rawValue`; `.preferredColorScheme(.dark)` yerine `.preferredColorScheme(AppearanceSetting(rawValue: appearance)?.colorScheme)`.
- [ ] **Step 6: `SettingsView`**: Dil bölümünün altına `SettingsSectionHeader(title: loc.t("appearance"))` + üç seçenekli segment (`Picker` `.segmented`) aynı `@AppStorage`.
- [ ] **Step 7: `project.yml` sürümü 1.2.0 / 12; `xcodegen generate`**
- [ ] **Step 8: Testi çalıştır, PASS; uygulamayı derle (`xcodebuild build`), widget hedefi de derlenmeli**
- [ ] **Step 9: Commit** `chore: 1.2.0 (12), semantik/marka renk ayrımı, görünüm tercihi`

---

### Task 2: `SpeedTestResult` genişletme (geriye uyumlu)

**Files:**
- Modify: `SpeedLab/Models/SpeedTestResult.swift`
- Test: `SpeedLabTests/SpeedTestResultTests.swift`

**Interfaces:**
- Produces: `SpeedTestResult` yeni opsiyonel alanlar `downloadSamples: [Double]?`, `uploadSamples: [Double]?`, `connectionType: String?` ("wifi" | "cellular" | "wired"), `carrier: String?`; init'e aynı adlı varsayılan-nil parametreler ve `date: Date = Date()` (testlerde geçmiş tarih üretmek için).
- Produces: `var effectiveConnectionType: String` → `connectionType ?? (ssid.isEmpty || ssid == "-" ? "cellular" : "wifi")`.
- Produces: `enum ConnectionKind: String { case wifi, cellular, wired }` (filtrede kullanılır).

- [ ] **Step 1: Failing test**

```swift
final class SpeedTestResultTests: XCTestCase {
    func test_decodesLegacyRecordWithoutNewFields() throws {
        let legacy = """
        [{"id":"5E4C0F3A-1B2C-4D5E-8F90-ABCDEF123456","downloadSpeed":37.5,"uploadSpeed":9.5,"ping":147,"jitter":37.4,"ssid":"-","isp":"Vodafone","ipAddress":"-","date":734000000}]
        """.data(using: .utf8)!
        let r = try JSONDecoder().decode([SpeedTestResult].self, from: legacy)
        XCTAssertEqual(r.count, 1)
        XCTAssertNil(r[0].downloadSamples)
        XCTAssertEqual(r[0].effectiveConnectionType, "cellular")
    }
    func test_wifiInferredFromSSID() {
        let r = SpeedTestResult(downloadSpeed: 1, uploadSpeed: 1, ping: 1, jitter: 1, ssid: "Ev", isp: "", ipAddress: "")
        XCTAssertEqual(r.effectiveConnectionType, "wifi")
    }
    func test_roundTripWithSamples() throws {
        let r = SpeedTestResult(downloadSpeed: 85.5, uploadSpeed: 20, ping: 23, jitter: 4.1, ssid: "Ev", isp: "Turknet", ipAddress: "1.2.3.4", downloadSamples: [10, 50, 85.5], uploadSamples: [5, 20], connectionType: "wifi", carrier: "Turknet")
        let d = try JSONDecoder().decode(SpeedTestResult.self, from: JSONEncoder().encode(r))
        XCTAssertEqual(d.downloadSamples, [10, 50, 85.5]); XCTAssertEqual(d.carrier, "Turknet")
    }
}
```

- [ ] **Step 2: FAIL gör (extra argument / missing member)**
- [ ] **Step 3: Modeli genişlet** (opsiyonel alanlar, init, `effectiveConnectionType`, `ConnectionKind`); `Codable` sentezi opsiyonelleri eksik anahtarda nil bırakır, özel decoder gerekmez.
- [ ] **Step 4: PASS**
- [ ] **Step 5: Commit** `feat(model): örnek dizileri, bağlantı tipi ve sağlayıcı alanları (geriye uyumlu)`

---

### Task 3: Skala ve bağlam mantığı

**Files:**
- Create: `SpeedLab/Models/GaugeScale.swift`
- Create: `SpeedLab/Models/SpeedContext.swift`
- Modify: `SpeedLab/Services/LocalizationService.swift` (bant anahtarları)
- Test: `SpeedLabTests/GaugeScaleTests.swift`, `SpeedLabTests/SpeedContextTests.swift`

**Interfaces:**
- Produces: `enum GaugeScale { static let maxMbps = 1000.0; static let labels: [Double] = [0,1,5,10,50,100,500,1000]; static func fraction(_ mbps: Double) -> Double; static func label(_ v: Double) -> String }` — `fraction = log10(v+1)/log10(1001)`, negatif/NaN → 0, ≥1000 → 1; `label(1000) == "1G"`.
- Produces: `enum SpeedContext { enum Metric { case download, upload, ping }; static func bandKey(_ metric: Metric, value: Double) -> String; static func deltaPercent(current: Double, history: [Double]) -> Int?; static func median(_ xs: [Double]) -> Double? }`. `bandKey` döndürdüğü anahtarlar: `band_dl_music`, `band_dl_hd`, `band_dl_4k`, `band_dl_office`, `band_dl_fiber`, `band_ul_weak`, `band_ul_call`, `band_ul_stream`, `band_ping_gaming`, `band_ping_good`, `band_ping_laggy`. `deltaPercent`: `history` son 10 değerin medyanına göre yüzde, `history.count < 2` → nil, |fark| < 5 → 0.
- Sözlük metinleri (TR/EN): müzik/web, HD video, "4K yayın için yeterli", "ev ofisi için ferah", "fiber sınıfı"; "görüşmede zorlanır", "video görüşme için yeterli", "yayın/yükleme için iyi"; "oyun için ideal", "iyi", "gecikmeli"; ayrıca `context_avg` = "ortalamada", `context_up` = "↑ %{p} ortalamaya göre", `context_down` = "↓ %{p} ortalamaya göre".

- [ ] **Step 1: Failing tests**

```swift
final class GaugeScaleTests: XCTestCase {
    func test_edges() {
        XCTAssertEqual(GaugeScale.fraction(0), 0, accuracy: 1e-9)
        XCTAssertEqual(GaugeScale.fraction(1000), 1, accuracy: 1e-9)
        XCTAssertEqual(GaugeScale.fraction(5000), 1)
        XCTAssertEqual(GaugeScale.fraction(-3), 0)
        XCTAssertEqual(GaugeScale.fraction(.nan), 0)
    }
    func test_monotonicAndMid() {
        XCTAssertEqual(GaugeScale.fraction(100), log10(101)/log10(1001), accuracy: 1e-9)
        XCTAssertLessThan(GaugeScale.fraction(10), GaugeScale.fraction(50))
    }
    func test_labels() { XCTAssertEqual(GaugeScale.label(1000), "1G"); XCTAssertEqual(GaugeScale.label(50), "50") }
}
final class SpeedContextTests: XCTestCase {
    func test_downloadBands() {
        XCTAssertEqual(SpeedContext.bandKey(.download, value: 4.9), "band_dl_music")
        XCTAssertEqual(SpeedContext.bandKey(.download, value: 37.5), "band_dl_4k")
        XCTAssertEqual(SpeedContext.bandKey(.download, value: 100), "band_dl_fiber")
    }
    func test_uploadAndPingBands() {
        XCTAssertEqual(SpeedContext.bandKey(.upload, value: 9.5), "band_ul_call")
        XCTAssertEqual(SpeedContext.bandKey(.ping, value: 23), "band_ping_gaming")
        XCTAssertEqual(SpeedContext.bandKey(.ping, value: 147), "band_ping_laggy")
    }
    func test_delta() {
        XCTAssertNil(SpeedContext.deltaPercent(current: 50, history: [40]))
        XCTAssertEqual(SpeedContext.deltaPercent(current: 56, history: [50, 50, 50]), 12)
        XCTAssertEqual(SpeedContext.deltaPercent(current: 51, history: [50, 50, 50]), 0)
        XCTAssertEqual(SpeedContext.median([3, 1, 2]), 2); XCTAssertNil(SpeedContext.median([]))
    }
}
```

- [ ] **Step 2: FAIL gör**
- [ ] **Step 3: İki dosyayı yaz; sözlüğe 14 anahtarı ekle**
- [ ] **Step 4: PASS**
- [ ] **Step 5: Commit** `feat: logaritmik kadran skalası ve sonuç bağlam bantları`

---

### Task 4: ViewModel — örnekleme, bağlantı tipi, reklam zamanlaması, ödüllü reklamın kaldırılması

**Files:**
- Modify: `SpeedLab/ViewModels/SpeedTestViewModel.swift`
- Modify: `SpeedLab/Services/NetworkService.swift` (`getConnectionKind() -> ConnectionKind?` ekle; mevcut `getConnectionType()` kalır)
- Modify: `SpeedLab/Services/SpeedTestService.swift:15-47` (`measurePing` kayıp oranı döndürür)
- Modify: `SpeedLab/Services/AdManager.swift` (rewarded bölümü ve `rewardedAdUnitID` silinir)
- Modify: `SpeedLab/App/SpeedLabApp.swift:65` (`loadRewarded()` çağrısı silinir)
- Modify: `SpeedLab/Views/SpeedTestView.swift:191-211,218-222` (ödüllü düğme ve alert silinir — bu görünüm Task 6'da zaten yeniden yazılır; burada yalnız derlemeyi koru)
- Modify: `SpeedLab/Services/LocalizationService.swift` (`watch_ad_extra_test`, `reward_earned` kaldır)
- Create: `SpeedLab/Models/SampleBuffer.swift`
- Test: `SpeedLabTests/SampleBufferTests.swift`

**Interfaces:**
- Produces: `struct SampleBuffer { let capacity: Int; private(set) var values: [Double]; mutating func append(_ v: Double); init(capacity: Int = 60) }` — kapasite aşılınca en eskiyi atar.
- Produces: `SpeedTestService.measurePing(count:)` dönüşü `(ping: Double, jitter: Double, loss: Double)` olur; `loss = Double(count - başarılı) / Double(count)` (0–1).
- Produces (ViewModel): `@Published var downloadSamples = SampleBuffer()`, `@Published var uploadSamples = SampleBuffer()`, `@Published var connectionKind: ConnectionKind?`, `@Published var packetLoss: Double?`, `@Published var showResultCards = false`. `startTest()` akışı: ping → download (her progressHandler'da `downloadSamples.append(speed)`) → upload → `phase = .completed` → `Task.sleep(0.8 s)` → `showResultCards = true` → `Task.sleep(1.5 s)` → `AdManager.shared.showInterstitialIfNeeded()`. `resetValues()` tamponları sıfırlar. Kaydedilen `SpeedTestResult` yeni alanları doldurur (`connectionType: connectionKind?.rawValue`, `carrier: networkInfo.isp`).
- `gaugeValue` artık `GaugeScale.fraction(speed)` ile hesaplanır (200'e bölme kalkar).

- [ ] **Step 1: Failing test**

```swift
final class SampleBufferTests: XCTestCase {
    func test_capacityDropsOldest() {
        var b = SampleBuffer(capacity: 3)
        [1, 2, 3, 4].forEach { b.append($0) }
        XCTAssertEqual(b.values, [2, 3, 4])
    }
    func test_defaultCapacity60() { XCTAssertEqual(SampleBuffer().capacity, 60) }
}
```

- [ ] **Step 2: FAIL gör**
- [ ] **Step 3: `SampleBuffer.swift` yaz; ViewModel'i Interfaces'e göre güncelle; `NetworkService.getConnectionKind()` ekle (NWPathMonitor ile `.wifi/.cellular/.wiredEthernet` → enum, aksi nil)**
- [ ] **Step 4: Ödüllü reklamı kaldır** (AdManager, App, SpeedTestView, sözlük). `grep -rn "rewarded\|Rewarded\|watch_ad" SpeedLab` boş dönmeli.
- [ ] **Step 5: PASS + tüm hedefler derlenir**
- [ ] **Step 6: Commit** `feat(vm): canlı örnek tamponu, bağlantı tipi, kart/interstitial zamanlaması; ödüllü reklam kaldırıldı`

---

### Task 5: Kokpit kadranı (`DialGaugeView`)

**Files:**
- Create: `SpeedLab/Views/Gauge/DialGaugeView.swift`
- Create: `SpeedLab/Views/Gauge/DialGeometry.swift`
- Delete: `SpeedLab/Views/SpeedGaugeView.swift` (NeedleShape dahil; ShareCard kendi `ShareGaugeView`'ını kullanır, etkilenmez)
- Test: `SpeedLabTests/DialGeometryTests.swift`

**Interfaces:**
- Produces: `struct DialGeometry { let center: CGPoint; let radius: CGFloat; static let startDeg: Double = -135; static let sweepDeg: Double = 270; func point(fraction: Double, radius r: CGFloat) -> CGPoint; func angle(fraction: Double) -> Angle }` — saat yönü, 12'den −135° başlar (taslaktaki `start:-135, sweep:270`).
- Produces: `struct DialGaugeView: View { let speed: Double; let phase: SpeedTestPhase; let isUploading: Bool; let idleTitle: String }` — Canvas ile: arka ray (%7 opak beyaz, 14 pt), dolum (gradyan, son %6 beyaz uç + gölge), 60 tik (dolum gerisi cyan, ilerisi %22 beyaz, her 10'da uzun), 8 etiket (`GaugeScale.labels`, `GaugeScale.label`), ibre (beyaz 3.5 pt + cyan parıltı), göbek; kadran açıklığında büyük rakam (`.system(size: 64, weight: .heavy, design: .rounded).monospacedDigit()`, `contentTransition(.numericText())`) + "MBPS". Boşta rakam yerine `idleTitle` ("Başlat") ve `TimelineView(.animation)` ile 2 sn periyotlu nefes parıltısı. `isUploading` true iken dolum gradyanı mor→cyan. Animasyon: `@State animated: Double` `withAnimation(.spring(response: 0.45, dampingFraction: 0.65))` ile `GaugeScale.fraction(speed)`'e; faz `.idle`'da 0.5 sn ease ile 0'a. Boyut: genişlik 300 pt, yükseklik 270 pt.

- [ ] **Step 1: Failing test**

```swift
final class DialGeometryTests: XCTestCase {
    func test_startAndEndAngles() {
        let g = DialGeometry(center: CGPoint(x: 100, y: 100), radius: 100)
        XCTAssertEqual(g.angle(fraction: 0).degrees, -135, accuracy: 1e-9)
        XCTAssertEqual(g.angle(fraction: 1).degrees, 135, accuracy: 1e-9)
    }
    func test_topIsFractionHalf() {
        let g = DialGeometry(center: CGPoint(x: 100, y: 100), radius: 100)
        let p = g.point(fraction: 0.5, radius: 100)
        XCTAssertEqual(p.x, 100, accuracy: 1e-6); XCTAssertEqual(p.y, 0, accuracy: 1e-6)
    }
}
```

- [ ] **Step 2: FAIL gör**
- [ ] **Step 3: `DialGeometry.swift` ve `DialGaugeView.swift` yaz; `SpeedGaugeView.swift` sil; `SpeedTestView`'da geçici olarak `DialGaugeView(speed:phase:isUploading:idleTitle:)` kullan (tam düzen Task 6)**
- [ ] **Step 4: PASS + derleme**
- [ ] **Step 5: Görsel doğrulama**: simülatörde boşta ve test sırasında (gerçek ağ) iki ekran görüntüsü; taslaktaki kadranla kıyasla: etiketler rakamla çakışmıyor, uç beyaz parlıyor, ibre ucu dolumun içinde.
- [ ] **Step 6: Commit** `feat(gauge): Canvas tabanlı 270° logaritmik kokpit kadranı`

---

### Task 6: Ana ekran düzeni (A taslağı)

**Files:**
- Rewrite: `SpeedLab/Views/SpeedTestView.swift`
- Create: `SpeedLab/Views/Gauge/TelemetryStrip.swift`
- Create: `SpeedLab/Views/Gauge/LiveFlowGraph.swift`
- Create: `SpeedLab/Views/Gauge/ContextResultCard.swift`
- Modify: `SpeedLab/ViewModels/HistoryViewModel.swift` (`func recentDownloads(limit: Int = 10, kind: ConnectionKind?) -> [Double]` ve aynısı upload/ping için — bağlam farkı için)
- Modify: `SpeedLab/Services/LocalizationService.swift` (`packet_loss`, `live_flow`, `last_30s`, `queued`, `measuring_download`, `measuring_upload`)
- Modify: `SpeedLab/Views/OnboardingView.swift` (ilk sayfadaki kadran görseli `DialGaugeView(speed: 85.5, phase: .completed, …)` ile değiştirilir, metin aynı)

**Interfaces:**
- Consumes: `DialGaugeView`, `SpeedContext`, `SampleBuffer`, `vm.showResultCards`.
- Produces: `TelemetryStrip(ping: Double?, jitter: Double?, loss: Double?)` — üç cam çip, nil → "—". Kayıp yüzdesi `vm.packetLoss` (Task 4), `%.0f%%` biçiminde.
- Produces: `LiveFlowGraph(download: [Double], upload: [Double], height: CGFloat = 110)` — Canvas: indirme cyan dolgu + çizgi, yükleme mor kesik çizgi, son nokta beyaz; boş dizide düz çizgi; Y ekseni dizilerin maksimumuna otomatik.
- Produces: `ContextResultCard(icon: String, label: String, value: String, unit: String, color: Color, context: String?)` — `ResultCard`'ın yerine; `context` yeşil (↑/bant) veya ikincil renk.
- Düzen (yukarıdan): başlık + durum satırı (faz · `vm.networkInfo.isp` · bağlantı tipi) → `TelemetryStrip` → `DialGaugeView` (dokununca `startTest`) → `LiveFlowGraph` (başlık "Canlı akış · İndirme" / bitince "Son 30 sn") → `showResultCards` ise kartlar (İndirme/Yükleme, Ping/Jitter) `.transition(.move(edge: .top).combined(with: .opacity))` + ağ bilgi kartı + paylaş düğmesi. Eski `ProgressView`, "tap_to_start" metni, tamamlanma rozeti ve halka parıltıları kaldırılır.

- [ ] **Step 1: `SpeedTestView`'ı yeniden yaz, üç alt görünümü oluştur, HistoryViewModel'e `recent…` yardımcılarını ekle**
- [ ] **Step 2: Derle; `xcodebuild test` ile tüm mevcut testler PASS**
- [ ] **Step 3: Görsel doğrulama**: boşta, indirme sırasında, tamamlandıktan sonra; TR/EN, koyu/açık (en az 6 görüntü). Kontrol listesi: telemetri çipleri tek satır, kadran altındaki rakam etiketlerle çakışmıyor, grafik kartı 110 pt, kartlar kayarak geliyor, banner kadranı örtmüyor, açık temada tüm metinler okunuyor.
- [ ] **Step 4: Commit** `feat(ana ekran): telemetri şeridi, canlı akış grafiği, bağlamlı sonuç kartları`

---

### Task 7: Geçmiş — grafik, filtre, Pro ufku

**Files:**
- Modify: `SpeedLab/ViewModels/HistoryViewModel.swift`
- Create: `SpeedLab/Models/HistoryQuery.swift`
- Create: `SpeedLab/Views/History/HistoryChartView.swift`
- Rewrite: `SpeedLab/Views/HistoryView.swift` (liste `ScrollView+LazyVStack` yerine `List` + `.listStyle(.plain)` + şeffaf satır zemini; satırda `HistoryCard`: bağlantı simgesi + sağlayıcı/SSID + 3 rakam; `.swipeActions(edge: .trailing)` ile sil, `contextMenu` kaldırılır)
- Modify: `SpeedLab/Services/LocalizationService.swift` (`range_day`, `range_week`, `range_month`, `filter_all`, `filter_wifi`, `filter_cellular`, `free_chart_note` = "Son 3 test · Pro ile tüm geçmiş", `export`)
- Test: `SpeedLabTests/HistoryQueryTests.swift`

**Interfaces:**
- Produces: `enum HistoryRange: String, CaseIterable { case day, week, month; var seconds: TimeInterval }` (86400, 7×86400, 30×86400).
- Produces: `struct HistoryQuery { static func filter(_ xs: [SpeedTestResult], kind: ConnectionKind?, carrier: String?, range: HistoryRange, now: Date, isPro: Bool, freeChartLimit: Int = 3) -> [SpeedTestResult] }` — tarih artan sırada döner; `isPro == false` ise `range` yok sayılır ve en yeni 3 kayıt döner.
- Produces (ViewModel): `@Published var range: HistoryRange = .day`, `@Published var kind: ConnectionKind? = nil`, `@Published var carrier: String? = nil`, `var chartResults: [SpeedTestResult]` (HistoryQuery ile), `var carriers: [String]` (benzersiz, alfabetik). `func requestRange(_ r: HistoryRange, isPro: Bool) -> Bool` — Pro değilse ve `r != .day` ise false döner (görünüm Pro sayfasını açar).
- Produces: `HistoryChartView(results: [SpeedTestResult])` — `Chart` ile `LineMark`+`AreaMark` indirme (cyan), `LineMark` yükleme (mor), ping ikinci eksende `.foregroundStyle(.secondary)`; 0 kayıt → "no_results", 1 kayıt → tek nokta.

- [ ] **Step 1: Failing test**

```swift
final class HistoryQueryTests: XCTestCase {
    private func r(_ dl: Double, daysAgo: Double, ssid: String = "Ev", isp: String = "Turknet") -> SpeedTestResult {
        SpeedTestResult(downloadSpeed: dl, uploadSpeed: 1, ping: 1, jitter: 1, ssid: ssid, isp: isp, ipAddress: "",
                        date: Date(timeIntervalSinceNow: -daysAgo * 86400))
    }
    func test_freeReturnsNewestThreeIgnoringRange() {
        let xs = [r(1, daysAgo: 0), r(2, daysAgo: 1), r(3, daysAgo: 2), r(4, daysAgo: 40)]
        let out = HistoryQuery.filter(xs, kind: nil, carrier: nil, range: .month, now: Date(), isPro: false)
        XCTAssertEqual(out.map(\.downloadSpeed), [3, 2, 1])
    }
    func test_proRangeAndKindFilter() {
        let xs = [r(1, daysAgo: 0), r(2, daysAgo: 3, ssid: "-"), r(3, daysAgo: 10), r(4, daysAgo: 40)]
        XCTAssertEqual(HistoryQuery.filter(xs, kind: nil, carrier: nil, range: .week, now: Date(), isPro: true).count, 2)
        XCTAssertEqual(HistoryQuery.filter(xs, kind: .cellular, carrier: nil, range: .month, now: Date(), isPro: true).map(\.downloadSpeed), [2])
    }
    func test_emptyAndSingle() {
        XCTAssertTrue(HistoryQuery.filter([], kind: nil, carrier: nil, range: .day, now: Date(), isPro: true).isEmpty)
        XCTAssertEqual(HistoryQuery.filter([r(9, daysAgo: 0)], kind: nil, carrier: "Turknet", range: .day, now: Date(), isPro: true).count, 1)
    }
}
```

- [ ] **Step 2: FAIL gör**
- [ ] **Step 3: `HistoryQuery.swift`, ViewModel alanları, `HistoryChartView`, `HistoryView` yeniden yazımı; sözlük anahtarları**
- [ ] **Step 4: PASS + derleme**
- [ ] **Step 5: Görsel doğrulama**: ücretsiz hesap (3 test + not), Pro simülasyonu (`SharedStore().setPro(true)` ile değil, `StoreViewModel.isPro` debug bayrağı: `#if DEBUG` `UserDefaults.standard.bool(forKey: "debug_pro")`), hafta görünümü, filtre açık; TR/EN, koyu/açık.
- [ ] **Step 6: Commit** `feat(geçmiş): Charts grafiği, aralık ve bağlantı filtresi, ücretsiz 3 test sınırı`

---

### Task 8: Dışa aktarma (CSV + PDF, Pro)

**Files:**
- Create: `SpeedLab/Services/ExportService.swift`
- Modify: `SpeedLab/Views/HistoryView.swift` (başlık satırına "Dışa aktar" düğmesi → `confirmationDialog` CSV / PDF → `UIActivityViewController`, `presentShare` kalıbı `SpeedTestView`'dan kopyalanmaz: ortak `ShareSheet.present(items:)` yardımcısı `SpeedLab/Extensions/ShareSheet.swift`'e taşınır ve iki görünüm de onu kullanır)
- Create: `SpeedLab/Extensions/ShareSheet.swift`
- Modify: `SpeedLab/Services/LocalizationService.swift` (`export_csv`, `export_pdf`, `export_title` = "SpeedLab geçmişi")
- Test: `SpeedLabTests/ExportServiceTests.swift`

**Interfaces:**
- Produces: `enum ExportService { static func csv(_ results: [SpeedTestResult]) -> String; static func pdf(results: [SpeedTestResult], range: HistoryRange, chart: UIImage?, title: String) -> Data; static func fileName(kind: String, range: HistoryRange, now: Date) -> String }`.
  - CSV başlık satırı tam olarak: `date,connection,ssid,carrier,download_mbps,upload_mbps,ping_ms,jitter_ms,ip`; tarih ISO 8601 (`ISO8601DateFormatter`), ondalık nokta, iki basamak; alanlarda virgül varsa çift tırnak.
  - PDF: A4 (595×842 pt), üstte başlık + aralık, özet satırı (medyan ↓ ↑ ping), varsa grafik görüntüsü (genişlik 515 pt), tablo satırları 16 pt yükseklik, sayfa taşınca yeni sayfa; marka renkleri (`npBrand*`).
  - `fileName("csv", .week, now)` → `SpeedLab-2026-10-27-2026-11-02.csv` biçimi (başlangıç = now − range).
- Görünüm: Pro değilse düğme Pro sayfasını açar, dosya üretmez.

- [ ] **Step 1: Failing test**

```swift
final class ExportServiceTests: XCTestCase {
    func test_csvHeaderAndRow() {
        let r = SpeedTestResult(downloadSpeed: 85.5, uploadSpeed: 9.5, ping: 23, jitter: 4.1, ssid: "Ev, Salon", isp: "Turknet", ipAddress: "1.2.3.4", connectionType: "wifi", carrier: "Turknet")
        let lines = ExportService.csv([r]).split(separator: "\n")
        XCTAssertEqual(lines[0], "date,connection,ssid,carrier,download_mbps,upload_mbps,ping_ms,jitter_ms,ip")
        XCTAssertTrue(lines[1].hasSuffix(",wifi,\"Ev, Salon\",Turknet,85.50,9.50,23.00,4.10,1.2.3.4"))
    }
    func test_csvEmptyIsHeaderOnly() { XCTAssertEqual(ExportService.csv([]).split(separator: "\n").count, 1) }
    func test_pdfProducesDocument() {
        let data = ExportService.pdf(results: [], range: .day, chart: nil, title: "SpeedLab")
        XCTAssertTrue(data.starts(with: Array("%PDF".utf8)))
        XCTAssertNotNil(PDFDocument(data: data)); XCTAssertEqual(PDFDocument(data: data)?.pageCount, 1)
    }
    func test_fileName() {
        let now = ISO8601DateFormatter().date(from: "2026-11-02T12:00:00Z")!
        XCTAssertEqual(ExportService.fileName(kind: "csv", range: .week, now: now), "SpeedLab-2026-10-26-2026-11-02.csv")
    }
}
```

- [ ] **Step 2: FAIL gör**
- [ ] **Step 3: `ExportService`, `ShareSheet`, HistoryView düğmesi + Pro kapısı; sözlük**
- [ ] **Step 4: PASS + derleme**
- [ ] **Step 5: Görsel doğrulama**: Pro simülasyonunda PDF'i paylaşım sayfasından Dosyalar'a kaydet, Preview'da aç; CSV'yi `cat` ile kontrol.
- [ ] **Step 6: Commit** `feat(dışa aktarma): CSV ve PDF geçmiş dışa aktarma (Pro)`

---

### Task 9: WiFi sekmesi — dürüst sinyal kalitesi

**Files:**
- Modify: `SpeedLab/Models/SpeedTestResult.swift` (`NetworkInfo`'ya `signalQuality: Double?` (0–1), `radioTech: String?`, `connectionKind: ConnectionKind?` ekle; `signalStrength` kalır ama kullanılmaz)
- Modify: `SpeedLab/Services/NetworkService.swift` (`getCurrentSSID` yanında `fetchHotspot() -> (ssid: String, bssid: String, quality: Double?)`; `getRadioTech() -> String?` CoreTelephony `serviceCurrentRadioAccessTechnology` → "5G" / "LTE" / "3G"; `getNetworkInfo()` bunları doldurur)
- Modify: `SpeedLab/ViewModels/WiFiViewModel.swift` (`SignalPoint.strength: Int` → `quality: Double`; `startMonitoring` 2 sn'de bir yalnız hotspot okur, `refresh` çağırmaz; `hasSignalData: Bool`)
- Create: `SpeedLab/Models/SignalQuality.swift`
- Create: `SpeedLab/Views/WiFi/SignalQualityGauge.swift`
- Rewrite: `SpeedLab/Views/WiFiAnalyzerView.swift`
- Modify: `SpeedLab/Services/LocalizationService.swift` (`signal_quality`, `signal_weak/fair/good/excellent`, `signal_unavailable` = "Ölçülemiyor", `ios_not_shared` = "iOS paylaşmıyor", `band`, `channel`, `bssid`, `public_ip`, `radio_tech`)
- Test: `SpeedLabTests/SignalQualityTests.swift`

**Interfaces:**
- Produces: `enum SignalQuality { static func bandKey(_ q: Double?) -> String; static func percent(_ q: Double?) -> Int? }` — nil veya ≤0 → `signal_unavailable`/nil; <0.3 weak, <0.55 fair, <0.8 good, else excellent.
- Produces: `SignalQualityGauge(quality: Double?)` — 180° yarım kadran, renk yeşil→sarı→kırmızı, altında yüzde + basamak; nil'de soluk ve "Ölçülemiyor".
- Görünüm: başlık + Yenile → `SignalQualityGauge` → bağlantı rozeti (tür + radyo tipi) → satırlar: SSID, BSSID, bant (`ios_not_shared`), kanal (`ios_not_shared`), yerel IP, genel IP, ISP → `hasSignalData` ise 60 sn mini grafik (`LiveFlowGraph` tek seri ile yeniden kullanılır). `.onAppear { vm.startMonitoring() } .onDisappear { vm.stopMonitoring() }`.

- [ ] **Step 1: Failing test**

```swift
final class SignalQualityTests: XCTestCase {
    func test_bands() {
        XCTAssertEqual(SignalQuality.bandKey(nil), "signal_unavailable")
        XCTAssertEqual(SignalQuality.bandKey(0), "signal_unavailable")
        XCTAssertEqual(SignalQuality.bandKey(0.2), "signal_weak")
        XCTAssertEqual(SignalQuality.bandKey(0.5), "signal_fair")
        XCTAssertEqual(SignalQuality.bandKey(0.7), "signal_good")
        XCTAssertEqual(SignalQuality.bandKey(0.95), "signal_excellent")
    }
    func test_percent() { XCTAssertEqual(SignalQuality.percent(0.734), 73); XCTAssertNil(SignalQuality.percent(0)) }
}
```

- [ ] **Step 2: FAIL gör**
- [ ] **Step 3: Model/servis/VM/görünüm değişiklikleri; sözlük**
- [ ] **Step 4: PASS + derleme**
- [ ] **Step 5: Görsel doğrulama**: simülatörde (SSID "Simulator WiFi", kalite nil → "Ölçülemiyor") ve mümkünse gerçek cihazda bir görüntü; TR/EN, koyu/açık.
- [ ] **Step 6: Commit** `feat(wifi): sinyal kalitesi kadranı, radyo tipi, iOS'un vermediği alanlar dürüst gösterim`

---

### Task 10: Pro ekranı fayda kartları ve gerçek olmayan vaatlerin temizlenmesi

**Files:**
- Modify: `SpeedLab/Views/SettingsView.swift:255-310` (`marketingContent` ve legacy liste)
- Create: `SpeedLab/Views/Pro/ProBenefitCards.swift`
- Modify: `SpeedLab/Services/LocalizationService.swift` (`feature_wifi_map` kaldır; `feature_export` metni "CSV / PDF dışa aktarma"; `benefit_no_ads_sub`, `benefit_history_sub`, `benefit_export_sub`)

**Interfaces:**
- Produces: `ProBenefitCards()` — yatay kaydırılan üç kart (reklamsız: banner silik→temiz; tam geçmiş + grafik: `HistoryChartView` örnek veriyle; dışa aktarma: CSV/PDF simgeleri + örnek dosya adı). Örnek veri `SpeedTestResult` dizisi sabit.
- Karar (plan yazarının): "WiFi sinyal haritası" özelliği uygulamada yok → Pro listesinden kaldırılır (App Review riski, spec'in "gerçek olmayan vaat" ilkesi).

- [ ] **Step 1: `ProBenefitCards` yaz; iki paywall'da `ProFeatureRow` listesinin üstüne koy; `feature_wifi_map` satırını ve anahtarını sil**
- [ ] **Step 2: Derleme; `grep -rn feature_wifi_map SpeedLab` boş**
- [ ] **Step 3: Görsel doğrulama**: Pro sayfası iOS 17+ (modern) görünümü, TR/EN.
- [ ] **Step 4: Commit** `feat(pro): fayda önizleme kartları; var olmayan WiFi haritası vaadi kaldırıldı`

---

### Task 11: İkon (2 · Lab kadranı)

**Files:**
- Create: `uretim/ikon/icon2.svg` (taslak HTML'deki `icon2` çıktısı, 1024×1024, `<svg>` olarak dışa aktarılır)
- Create: `uretim/ikon/uret.mjs` (Playwright ile SVG → `AppIcon.png` 1024 + katman PNG'leri: `zemin.png`, `cam.png`, `skala.png`, `dolum-ibre.png`, `gobek.png`)
- Replace: `SpeedLab/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- Create (iOS 26): `SpeedLab/Assets.xcassets/AppIcon.icon/` — Icon Composer paketi; `project.yml`'de `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` aynı kalır.
- Modify: `SpeedLab/Views/ShareCard/ShareGaugeView.swift` ve `SpeedLabWidget/SpeedLabWidget.swift` (`gauge.high` sembolü yerine küçük `DialGeometry` tabanlı mini kadran yerine basit: `Image("IkonKucuk")` 64 pt asset eklenir, `SpeedLab/Assets.xcassets/IkonKucuk.imageset`)

**Interfaces:**
- Produces: `uretim/ikon/uret.mjs` çalışınca yukarıdaki PNG'ler oluşur; `AppIcon.png` sRGB, alfa yok, 1024×1024 (`sips -g hasAlpha` → no).

- [ ] **Step 1: `uret.mjs` yaz** (taslak `icons.html`'den `icon2` fonksiyonunu tek SVG'ye kopyala; katmanlar için aynı çizimi parçalara ayır, her birini şeffaf zeminde ayrı PNG olarak çek).
- [ ] **Step 2: Çalıştır: `node uretim/ikon/uret.mjs`; `sips -g pixelWidth -g hasAlpha SpeedLab/Assets.xcassets/AppIcon.appiconset/AppIcon.png` → 1024, no**
- [ ] **Step 3: Icon Composer paketi**: Xcode 27 ile gelen Icon Composer'da `icon2` katmanlarını içe aktar, `AppIcon.icon` olarak Assets'e kaydet (GUI adımı: Tunca yapar ya da `open -a "Icon Composer"` ile birlikte). Paket yoksa derleme PNG ikonla devam eder; bu adım sürümü bloke etmez.
- [ ] **Step 4: `IkonKucuk` asset'i, widget ve ShareCard'da kullanım; derleme**
- [ ] **Step 5: Görsel doğrulama**: simülatör ana ekranında ikon (`xcrun simctl io … screenshot` ana ekran), widget galerisi, paylaşım kartı render'ı.
- [ ] **Step 6: Commit** `feat(ikon): Lab kadranı ikonu, küçük logo asset'i, Icon Composer katmanları`

---

### Task 12: Tipografi, açık tema cilası ve onboarding

**Files:**
- Modify: `SpeedLab/Views/SpeedTestView.swift`, `HistoryView.swift`, `WiFiAnalyzerView.swift`, `SettingsView.swift`, `OnboardingView.swift` — `.foregroundColor(.white)` → `.npTextPrimary`; gradyan yalnız kadran ve "Lab" başlığında; birim metinleri `%45` boyut + `npTextSecondary`; rakamlar `.monospacedDigit()`.
- Modify: `SpeedLab/Extensions/Glass.swift` (`AuroraBackground` açık temada leke opaklıkları %38/32/28 → %18/14/12; `GlassCard` kenar çizgisi açıkta `.black.opacity(0.06)`)

- [ ] **Step 1: `grep -rn "foregroundColor(.white)" SpeedLab/Views` listesini semantik renge çevir (ShareCard ve widget hariç)**
- [ ] **Step 2: Glass açık tema ayarı; derleme**
- [ ] **Step 3: Görsel doğrulama**: dört sekme + Pro sayfası + onboarding, açık temada; kontrast kontrolü: metin/zemin oranı ≥ 4.5:1 (`npTextPrimary #0B1020` / `#F4F6FB` = 17:1, ikincil `#5B6478` / `#F4F6FB` = 5.6:1).
- [ ] **Step 4: Commit** `style: semantik metin renkleri, açık tema cilası, tipografi disiplini`

---

### Task 13: Mağaza görselleri, "What's New", son doğrulama

**Files:**
- Create: `uretim/magaza/cek.sh` (simülatörde 5 ekranı TR ve EN için yakalar: kadran (test sırasında), tamamlanmış sonuç, geçmiş grafiği (Pro debug bayrağı), WiFi, Pro sayfası; çıktı `uretim/magaza/<dil>/<n>-<ad>.png`, 1320×2868)
- Create: `docs/whats-new-1.2.0.md` (TR + EN metin)
- Modify: `docs/APP_REVIEW_NOTES_v1.2.0.md` (yeni: dışa aktarma Pro'da nasıl bulunur, WiFi sinyal kalitesinin kaynağı, reklam yerleşimi)

- [ ] **Step 1: `cek.sh` yaz ve çalıştır; 10 görüntü oluşur, her biri açılıp kontrol edilir**
- [ ] **Step 2: What's New (TR/EN, ≤ 4000 karakter, 5 madde: kokpit kadranı + canlı grafik, bağlamlı sonuçlar, geçmiş grafiği ve filtre, CSV/PDF dışa aktarma (Pro), açık tema ve yeni ikon)**
- [ ] **Step 3: Tam test paketi: `xcodebuild test … -only-testing:SpeedLabTests` → tüm sınıflar PASS**
- [ ] **Step 4: Eski veri testi**: simülatöre 1.1.2 formatında 12 kayıtlık JSON'u `speed_test_history` anahtarına yaz (`xcrun simctl spawn … defaults write com.vialab.speedlab …`), uygulamayı aç, geçmiş ve grafik çalışıyor.
- [ ] **Step 5: Performans**: Instruments Time Profiler ile test sırasında ana iş parçacığı %40 altı (simülatörde kaba ölçüm; cihaz ölçümü Tunca'nın iPhone'unda).
- [ ] **Step 6: Commit** `chore(1.2.0): mağaza görselleri, What's New, inceleme notları`
- [ ] **Step 7: Tunca'ya rapor**: görüntüler Masaüstü'ne kopyalanır, mağazaya yükleme Tunca "yükle" demeden yapılmaz.
