# SpeedLab v1.0.2 (build 5) — App Review Notes

Bu doküman v1.0.1 reddi (Submission 436771ab-43e0-48e7-926a-16142124e903) sonrası yapılan değişiklikleri ve ASC'de manuel yapılması gereken adımları içerir.

---

## 1) Apple'ın 3 Red Sebebi ve Çözüm Özeti

| Guideline | Sorun | Çözüm |
|---|---|---|
| 5.1.2(i) | Privacy label "tracking" diyor ama ATT prompt görünmüyor | ATT prompt'un timing'i sertleştirildi (700ms delay + scenePhase guard) |
| 2.1(b) #1 | "Pro" referansı var ama IAP ürünleri review'a gönderilmemiş | **ASC'de manuel:** IAP'leri bu build ile birlikte review'a gönder |
| 2.1(b) #2 | IAP ürünleri binary'de bulunamadı | IAP'leri Active duruma getir + bu binary ile attach et |

---

## 2) Kodda Yapılan Değişiklikler (v1.0.2 / build 5)

### ATT Prompt Düzeltmesi
**Dosya:** `SpeedLab/App/SpeedLabApp.swift`

Önceki implementasyon `.task(id: scenePhase)` üzerinden ATT istiyordu — cold launch'ta window scene tam sunulmadan istek gittiği için iOS bazen prompt'u sessizce drop ediyordu (reviewer'ın görmediği senaryo).

Yeni implementasyon:
- `.task` (initial) **ve** `.onChange(of: scenePhase)` her ikisi de tetikliyor
- 700ms delay ile root window'un tam sunulmasını bekliyor
- `UIApplication.shared.applicationState == .active` çift kontrol
- `attCompleted` flag ile re-entry önlenmiş
- ATT cevabı alınmadan AdMob initialize edilmiyor

### Versiyon Bump
- `MARKETING_VERSION`: 1.0.1 → **1.0.2**
- `CURRENT_PROJECT_VERSION`: 4 → **5**
- `SettingsView` hard-coded "v1.0.0" string'i Bundle'dan dinamik okumaya çevrildi

---

## 3) App Store Connect'te YAPMAN GEREKEN (kod değil!) ⚠️

### Adım 1 — IAP Ürünlerini "Ready to Submit" yap
1. App Store Connect → SpeedLab → **In-App Purchases**
2. Şu iki ürünü aç:
   - `com.vialab.speedlab.pro.monthly` (Auto-Renewable Subscription)
   - `com.vialab.speedlab.pro.yearly` (Auto-Renewable Subscription)
3. Her biri için **eksik metadata'yı tamamla:**
   - Subscription Display Name
   - Description (TR + EN)
   - Promotional Image (App Review Screenshot zorunlu — 1024x1024 PNG, Pro upgrade ekranının screenshot'ı)
   - Pricing (Tier seçili olmalı)
   - Review Information → Screenshot (ProUpgradeSheet ekranını yükle)
4. Sağ üst → **Save** → **Submit for Review**
5. Durum **"Waiting for Review"** olmalı

### Adım 2 — IAP'leri bu binary ile attach et
1. ASC → SpeedLab → App Store → **1.0.2 Prepare for Submission**
2. Sayfayı aşağı kaydır → **In-App Purchases and Subscriptions** bölümü
3. **+ butonuna** bas → her iki IAP'yi seç (monthly + yearly)
4. Kaydet

### Adım 3 — Privacy / ATT bölümünü kontrol et
1. ASC → App Privacy → Privacy Settings
2. **Data Used to Track You** altında "Device ID" ve "Advertising Data" işaretli OLMALI (AdMob için)
3. Bu işaretliyse → ATT prompt zorunlu (kodda var, hazır)
4. Eğer "tracking yapmıyoruz" demek istiyorsan, bu kutuları kaldır VE AdMob personalized ads'i kapat (önerilmez, gelir düşer)

### Adım 4 — App Review Information
**Notes** alanına aşağıdaki metni yapıştır:

```
Hello App Review Team,

This submission addresses all three issues from rejection 436771ab-43e0-48e7-926a-16142124e903:

1. Guideline 5.1.2(i) — App Tracking Transparency
The ATT prompt is requested by SpeedLabApp.swift (lines 35-58) immediately after the
root window scene becomes active, with a 700ms delay to ensure the window has fully
presented (this fixes the silent-drop issue we believe caused the previous rejection).
The prompt appears on the very first cold launch, before any AdMob ad is loaded.
NSUserTrackingUsageDescription is set in Info.plist.

To reproduce: Delete the app, reinstall, launch — the ATT system alert appears within
1 second of the home screen / onboarding becoming visible.

2 + 3. Guideline 2.1(b) — In-App Purchases
The two auto-renewable subscriptions
(com.vialab.speedlab.pro.monthly and com.vialab.speedlab.pro.yearly) have been
submitted alongside this binary. They are reachable via:
Settings tab → "Pro'ya Yükselt" / "Upgrade to Pro" banner → Pro upgrade sheet.

Demo account: not required (no login).

To test IAP in sandbox:
- Settings → Pro banner → choose monthly or yearly → complete sandbox purchase.

Thank you for the review.
```

### Adım 5 — App Review Screen Recording (önerilen)
1. Fiziksel iPhone'da v1.0.2'yi TestFlight üzerinden yükle
2. Settings → Screen Recording başlat
3. Şunları kaydet (60-90 saniye):
   - Home Screen'den uygulamayı aç
   - Onboarding'i geç (Skip)
   - **ATT prompt görünmesi**
   - Settings tab → Pro banner → Pro sheet açılması
   - Bir sandbox satın alma tamamla
   - Geri Settings'e dön, Pro rozetini göster
4. Bu kaydı ASC → App Review Information → Notes alanına yükle (Attachment olarak)

---

## 4) Pre-Upload Checklist

- [x] ATT prompt timing düzeltildi (SpeedLabApp.swift)
- [x] MARKETING_VERSION 1.0.2'ye yükseltildi
- [x] CURRENT_PROJECT_VERSION 5'e yükseltildi
- [x] xcodebuild başarılı (Debug iphonesimulator)
- [ ] Archive + Upload (Xcode → Product → Archive → Distribute App → App Store Connect)
- [ ] ASC'de IAP'ler "Submit for Review" yapıldı
- [ ] ASC'de IAP'ler 1.0.2 binary'sine attach edildi
- [ ] App Review Notes yapıştırıldı
- [ ] Screen recording yüklendi (opsiyonel ama önerilir)
- [ ] Submit for Review

---

## 5) Yapma! (yaygın hatalar)

- ❌ IAP'leri ASC'de **submit etmeden** binary'yi göndermek → aynı 2.1(b) reddi
- ❌ ATT NSUserTrackingUsageDescription'ı **silmek** → fix değil, bug
- ❌ Privacy Label'dan "Tracking" işaretini kaldırıp prompt'u da silmek → AdMob personalized ads otomatik kapanır, IDFA gelmez, gelir düşer
- ❌ Bu binary'yi 1.0.1 ile aynı build number'da yüklemek (build mutlaka 5 olmalı)
