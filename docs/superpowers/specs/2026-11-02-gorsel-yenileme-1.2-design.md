# SpeedLab 1.2.0 — Görsel yenileme ve ciddi kullanım sürümü

Tarih: 2 Kasım 2026 · Durum: taslak, Tunca'nın onayı bekleniyor

## Amaç ve neden

SpeedLab (iOS, "Speed Test & WiFi", Apple ID 6761667861) 2 Kasım 2026'da App Store'a geri döndü.
Mevcut 1.1.2 çalışıyor ama "tek seferlik test" hissi veriyor: ana ekranın yarısı boş, sonuçlar bağlamsız,
geçmiş düz liste, WiFi sekmesi tek kelimelik durum veriyor, ikon rakiplerle aynı kalıpta.

1.2.0'ın hedefi: uygulamayı **ciddi, tekrar açılan bir ölçüm aracı** gibi gösterip hissettirmek.
Referans duygu: eski Ookla Speedtest'in kokpit kadranı (canlı ibre, skala, altında akan grafik). Birebir
kopya DEĞİL; aynı duyguyu SpeedLab'in kendi diliyle (indigo→cyan palet, koyu cam yüzeyler) vermek.

Seçilmiş taslaklar (bu klasörde):
- `2026-11-02-kadran-taslak.png` / `.html` → **A varyantı** (açık 270° kadran) seçildi.
- `2026-11-02-ikon-taslak.html` → **2 numaralı "Lab kadranı"** ikon seçildi.

## Hedefler
1. Ana ekran A taslağına göre yeniden: telemetri şeridi, 270° logaritmik kadran, parlayan ibre + ışık izi,
   kadran altında büyük rakam, canlı akış grafiği, test bitince kayarak gelen sonuç kartları.
2. Test boyunca hareket: kadran "ısınma", ibre salınımı, rakam akışı, bitişte yumuşak iniş. 60 fps.
3. Sonuçlara bağlam: ortalamaya göre fark (↑ %12) ve kullanım bandı ("4K yayın için yeterli").
4. Geçmiş: önce grafik (gün / hafta / ay), altta liste; bağlantı tipi ve operatör filtresi.
5. WiFi sekmesi: dBm, bant (2.4 / 5 / 6 GHz), kanal (iOS'un verdiği kadar), sinyal geçmişi grafiği.
6. Tipografi ve renk disiplini: tabular rakamlar, birimler küçük ve soluk, gradyan yalnızca kadran ve
   başlıkta.
7. Açık tema; sistem temasını takip eder. Mevcut koyu tema birincil kalır.
8. Pro ekranında fayda önizlemeleri (reklamsız, sınırsız geçmiş, grafik, dışa aktarma).
9. Yeni ikon (2 numara), iOS 26 için Icon Composer katmanlı sürüm + eski iOS için düz PNG.
10. Sürüm 1.2.0, build 12. Mağaza ekran görüntüleri ve "What's New" metni yenilenir (TR + EN).

## Hedef olmayanlar
- Yeni ölçüm motoru veya sunucu değişikliği. Mevcut `SpeedTestService` (Cloudflare uçları) kalır;
  yalnız örnekleme çıktısı canlı grafiği besleyecek şekilde genişler.
- Fiyat değişikliği. IAP kimlikleri aynı (`com.vialab.speedlab.pro.monthly/yearly`). Tek yeni Pro özelliği
  dışa aktarma (aşağıda); başka Pro özelliği eklenmez.
- Android, macOS (SpeedLabMac ayrı proje) ve widget görsellerinin yeniden tasarımı. Widget yalnız yeni
  renk/ikonla uyumlu kalacak şekilde dokunulur.
- iOS 16 altı. Hedef iOS 16.0 korunur; iOS 17+ özellikleri (`#Preview`, Observation) zorunlu değil.
- Metinle anlatılan "tanıtım" ekranları. Onboarding yalnız yeni görsellerle güncellenir, adım eklenmez.

## Anti-hedefler (teknik olarak çalışsa bile başarısızlık sayılır)
- Ookla Speedtest'in tanınan düzenini (cyan skala + kırmızı bölge + yeşil alt grafik) kopyalamak.
- Her yüzeye gradyan; vurgu kaybolur.
- Kadran animasyonunun eski cihazlarda (iPhone 11 sınıfı) takılması.
- Reklam yerleşiminin yeni ekranda kadranı ya da grafiği örtmesi.
- Açık temada okunmayan cam yüzeyler (kontrast WCAG AA altına düşmemeli).

## Kısıtlar
- SwiftUI, Swift 5.9, iOS 16.0+, XcodeGen (`project.yml`). Yeni dosyalar `project.yml`'e otomatik girer
  (klasör tabanlı hedefler); yeni asset kataloğu girdileri elle.
- Mevcut mimari: `ViewModels/*` ObservableObject + `@Published`; servisler sınıf. Bu korunur.
- AdMob: banner `3125134660`, interstitial `6092312428` (her test sonunda, Pro hariç). Yerleşim kuralı:
  banner yalnız sonuç kartlarının altında, kadran/grafik üstünde asla.
- Yerelleştirme `LocalizationService.t(_:)` ile TR/EN sözlük; yeni her metin iki dilde girilir.
- Widget App Group paylaşımı (`SharedStore`) bozulmaz; `SpeedTestResult` Codable şeması geriye uyumlu
  genişler (yeni alanlar opsiyonel, eski kayıtlar okunmaya devam eder).

## Karar verilmiş tasarım

### Ana ekran (Hız Testi sekmesi) — A taslağı
Yukarıdan aşağıya:
1. **Başlık**: "SpeedLab" (Lab cyan), altında durum satırı: faz · operatör · bağlantı tipi.
2. **Telemetri şeridi**: üç cam çip: Ping (ms), Jitter (ms), Kayıp (%). Test öncesi "—".
3. **Kadran**: 270° (saat 7'den saat 5'e), logaritmik skala, etiketler 0 · 1 · 5 · 10 · 50 · 100 · 500 · 1G.
   - Arka ray: ince, %7 beyaz. Dolum: indigo→mavi→cyan gradyan, dolumun son %6'sı beyaza parlayan uç.
   - 60 tik; dolumun gerisinde kalanlar cyan, ilerisi soluk.
   - İbre: ince beyaz çizgi, arkasında yumuşak cyan parıltı; göbek koyu disk + cyan halka.
   - Kadran açıklığında (altta) büyük rakam (88 pt, tabular, -3 harf aralığı) ve altında "MBPS".
   - Boşta: ibre 0'da, rakam yerine ortada "▶" yok; kadran kendisi dokunulabilir, ortada küçük
     "Başlat" etiketi + hafif nefes alan parıltı. (Mevcut play üçgeni kaldırılır.)
4. **Canlı akış grafiği**: cam kart, test süresince indirme (cyan dolgu) ve yükleme (mor kesik çizgi)
   örnekleri, son nokta beyaz. Boşta son testin eğrisi; hiç test yoksa düz çizgi.
5. **Sonuç kartları**: İndirme, Yükleme (ikişerli), altında Ping/Jitter satırı; her kartta bağlam satırı
   (ortalamaya göre fark veya kullanım bandı). Test bitince kadranın altından 0.35 sn'de kayarak gelir.
6. **Sonucu paylaş** düğmesi (mevcut ShareCard akışı) kartların altında.
7. Banner reklam (Pro değilse) en altta, tab çubuğunun üstünde.
8. "Reklam izle, ekstra test" ödüllü reklam düğmesi KALDIRILIR: kodda test sınırı yok, düğme işlevsiz.
   `rewardedAdUnitID` ve metinleri temizlenir (AdMob'daki birim silinmez, sadece kullanılmaz).
9. Interstitial zamanlaması: test bitişi → ibre 0.8 sn bekler → kartlar 0.35 sn kayar → 1.5 sn sonra
   interstitial (Pro hariç). Animasyon tamamen görülür; reklam kartların üstüne binmez.

Animasyon zamanlaması:
- Teste başlama: kadran rayı 0.4 sn'de "ısınır" (opaklık %7→%12), tikler soldan sağa 0.6 sn'de yanar.
- Ölçüm: ibre `spring(response: 0.45, dampingFraction: 0.65)` ile örneğe gider; rakam `contentTransition(.numericText())`.
- Faz geçişi (indirme→yükleme): ibre 0'a 0.5 sn'de iner, dolum rengi mor-cyan'a döner.
- Bitiş: ibre son değerde 0.8 sn bekler, kartlar kayar, hafif haptik (mevcut).
- Kadran çizimi `Canvas` + `TimelineView(.animation)`; her karede yalnız dolum/ibre yeniden çizilir,
  tik ve etiketler önbelleklenir.

### Örnekleme
`SpeedTestService.measureDownload/Upload` zaten `progressHandler(speed, progress)` veriyor; ViewModel bunu
`@Published var samples: [Sample]` (zaman, Mbps, yön) olarak biriktirir, en fazla 60 nokta (saniyede ~5).
Canlı grafik ve bitişteki "son 30 sn" bu diziden okunur. Sonuçla birlikte `SpeedTestResult`'a
`downloadSamples: [Double]?` ve `uploadSamples: [Double]?` eklenir (opsiyonel, geriye uyumlu).
Ayrıca filtre ve ortalama için `connectionType: String?` ("wifi" / "cellular" / "wired") ve
`carrier: String?` eklenir. Operatör/sağlayıcı = ipinfo `org` (mevcut `isp`); CoreTelephony operatör adı
iOS 16.4+'ta "--" döndüğü için kullanılmaz. Eski 1.1.2 kayıtları: `ssid` boş veya "-" ise hücresel, aksi
WiFi sayılır (decode sonrası türetme, kayıt değiştirilmez).

### Bağlam satırları
- Ortalama: son 10 testin medyanı (aynı bağlantı tipi varsa onunla); fark %5 altındaysa "ortalamada".
- Kullanım bandı (indirme için): <5 "müzik/web", 5–25 "HD video", 25–50 "4K yayın için yeterli",
  50–100 "ev ofisi için ferah", 100+ "fiber sınıfı". Yükleme için: <3 "görüşmede zorlanır",
  3–10 "video görüşme için yeterli", 10+ "yayın/yükleme için iyi". Ping: <30 "oyun için ideal",
  30–80 "iyi", 80+ "gecikmeli". Metinler iki dilde sözlükte.

### Geçmiş sekmesi
- Üstte zaman aralığı seçici (Gün / Hafta / Ay), çizgi grafik: indirme (cyan), yükleme (mor), ping ikinci eksende soluk.
- Altında özet çipler (mevcut) ve liste. Liste kartı: tarih, bağlantı tipi simgesi, operatör/SSID,
  üç rakam. Sola kaydır → sil.
- Filtre: tümü / WiFi / hücresel; operatör-SSID seçimi.
- Grafik `Charts` çerçevesiyle (iOS 16+). **Ücretsiz planda grafik son 3 testle çalışır** (Tunca'nın kararı);
  liste için mevcut ücretsiz sınır (`loadFree`, son 10) korunur. Ücretsizde Gün/Hafta/Ay seçici görünür ama
  Hafta/Ay dokununca Pro sayfası açılır; grafik üstünde "Son 3 test · Pro ile tüm geçmiş" küçük not.
  Pro'da tüm kayıtlar ve tüm aralıklar.

### WiFi sekmesi
- Gerçek: iOS herkese açık API'de dBm, bant ve kanal vermez. `NEHotspotNetwork.fetchCurrent` yalnız 0–1
  normalize `signalStrength` döndürür (bazı cihazlarda hep 0). Sahte dBm GÖSTERİLMEZ.
- Yarım kadran "Sinyal kalitesi" olarak çizilir: 0–1 değeri yüzde ve dört basamak (Zayıf / Orta / İyi /
  Mükemmel), renk yeşil→sarı→kırmızı. Değer 0 ve SSID yoksa kadran "Ölçülemiyor" durumunda soluk.
- Bilgi satırları: SSID, BSSID (kısaltılmış), yerel IP, genel IP, ISP, bağlantı tipi (WiFi / hücresel /
  Ethernet), hücreselde radyo tipi (5G / LTE, `CTTelephonyNetworkInfo.serviceCurrentRadioAccessTechnology`).
  Bant ve kanal satırı "iOS paylaşmıyor" notuyla soluk gösterilir (dürüstlük, boş "-" kalmaz).
- Sinyal geçmişi: `WiFiViewModel.startMonitoring()` sekme görünürken çalışır (şu an çağrılmıyor), 60 sn'lik
  mini grafik normalize değeri çizer; değer sabit 0 ise grafik gizlenir.
- Asıl "ciddi" derinlik bu sekmede değil Geçmiş grafiklerinde; mağaza görselinde WiFi sekmesi kalite kadranı
  + bilgi satırlarıyla gösterilir.
- Konum izni gerektiren alanlar (SSID) için mevcut izin akışı korunur.

### Tema
- `Color+Theme.swift` semantik hale gelir: `np*` adları kalır, değerler `UIColor { trait in ... }` ile
  açık/koyu çözer. Açık: zemin #F4F6FB, yüzey beyaz %70, metin #0B1020, ikincil #5B6478; vurgular aynı.
- Ayarlar'da "Görünüm: Sistem / Koyu / Açık" (varsayılan Sistem). Mevcut kullanıcılar için ilk açılışta
  Koyu'ya sabitlenmez; sistemi takip eder.
- Widget ve paylaşım kartı (ShareCard) KOYUYA SABİT kalır: marka görseli, her yerde aynı görünmeli.
  Bunun için `np*` renkleri iki sete ayrılır: `npBrand*` (sabit koyu, widget + ShareCard) ve semantik
  `np*` (trait'e göre çözen, uygulama görünümleri). Widget hedefi yalnız `npBrand*` kullanır.

### Tipografi
- Rakamlar `.monospacedDigit()`; büyük değerler `.system(size:…, weight: .heavy, design: .rounded)`.
- Birimler değerin %45'i boyutunda, ikincil renk, 4 pt boşluk.

### Dışa aktarma (Pro) — Tunca'nın kararı, 2 Kasım
- Geçmiş sekmesinde "Dışa aktar" düğmesi (Pro; ücretsizde dokununca Pro sayfası açılır).
- **CSV**: tüm kayıtlar; sütunlar tarih (ISO 8601), bağlantı tipi, SSID, sağlayıcı, indirme, yükleme, ping,
  jitter, IP. UTF-8, noktalı virgül değil virgül; ondalık nokta. Paylaşım sayfasıyla (`ShareLink` / UIActivity).
- **PDF**: seçili aralığın özeti tek sayfa: başlık + aralık, özet çipler (medyan indirme/yükleme/ping),
  Geçmiş grafiğinin görüntüsü (`ImageRenderer`), altında kayıt tablosu (sayfa taşarsa devam sayfaları).
  Koyu marka renkleriyle, `UIGraphicsPDFRenderer`. Dosya adı `SpeedLab-<başlangıç>-<bitiş>.pdf`.
- Pro sayfasındaki "CSV/PDF dışa aktarma" satırı artık gerçek özelliğe karşılık gelir.

### Pro ekranı
- `SubscriptionStoreView` kalır; üstüne üç fayda kartı: reklamsız (banner silik → temiz geçiş görseli),
  tam geçmiş + grafik ufku, CSV/PDF dışa aktarma. Görseller uygulama içi gerçek bileşenlerden render edilir.

### İkon (2 · Lab kadranı)
- Kaynak: `2026-11-02-ikon-taslak.html` içindeki `icon2` çizimi, 1024×1024 SVG'den PNG.
- iOS 26: Icon Composer ile katmanlar: zemin (radyal koyu), cam disk, skala + ray, dolum + ibre, göbek.
  Tinted/dark varyantlar otomatik üretilir, elle kontrol edilir.
- iOS 16–18: tek PNG (mevcut `AppIcon.appiconset`).
- Widget ve ShareCard'daki küçük logo yeni ikonla eşleşir.

### Sürüm ve mağaza
- `project.yml`: `MARKETING_VERSION 1.2.0`, `CURRENT_PROJECT_VERSION 12`.
- Mağaza görselleri: 6.9" ve 6.5" setleri, 5 görüntü (kadran, canlı grafik, geçmiş grafiği, WiFi, Pro).
  Üretim: simülatörden Playwright/xcrun ile yakalama + mevcut `app-store-screenshots` yaklaşımı.
- "What's New" TR/EN: yeni kadran ve canlı grafik, geçmiş grafiği, WiFi ayrıntıları, açık tema, yeni ikon.

## İnşaatçıya bırakılanlar
- `Canvas` içindeki geometri sabitleri (yarıçap, tik uzunlukları) — taslak HTML'deki oranlar referans.
- Logaritmik skala fonksiyonu: `f = log10(v+1)/log10(1001)`; 1G üstü değerler 1'de doyar.
- Grafik için `Charts` mı `Canvas` mı: Geçmiş'te `Charts`, canlı akışta `Canvas` (performans) önerilir.
- Açık tema cam yüzeylerin kesin blur/opaklık değerleri; AA kontrast sağlandığı sürece serbest.
- Test dosyaları: `SpeedLabTests` içine skala fonksiyonu, bağlam bandı eşikleri ve `SpeedTestResult`
  geriye uyumlu decode testi eklenir.

## Doğrulama
- Simülatörde iPhone 15 Pro ve iPhone SE (küçük ekran) üzerinde her sekmenin TR ve EN, koyu ve açık
  ekran görüntüsü alınır; Tunca onaylamadan mağazaya yükleme yapılmaz.
- Eski 1.1.2 geçmiş verisiyle (JSON) açılış testi.
- Instruments ile kadran animasyonunda ana iş parçacığı yükü iPhone 11'de %40 altı.
